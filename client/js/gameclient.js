define(['player',
  'character',
  'chat',
  'spelleffect',
  'party',
  'mob',
  'item',
  'chest',
  'entityfactory',
  'lib/sprintf.min',
  'lib/bison'
], function (
  Player,
  Character,
  Chat,
  SpellEffect,
  Party,
  Mob,
  Item,
  Chest,
  EntityFactory,
  sprintflib,
  BISON) {

  var GameClient = Class.extend({
    init: function (host, port) {
      this.connection = null;
      this.host = host;
      this.port = port;

      this.handlers = [];
      this.handlers[Types.Messages.WELCOME] = this.receiveWelcome;
      this.handlers[Types.Messages.MOVE] = this.receiveMove;
      this.handlers[Types.Messages.LOOTMOVE] = this.receiveLootMove;
      this.handlers[Types.Messages.ATTACK] = this.receiveAttack;
      this.handlers[Types.Messages.SPAWN] = this.receiveSpawn;
      this.handlers[Types.Messages.DESPAWN] = this.receiveDespawn;
      this.handlers[Types.Messages.SPAWN_BATCH] = this.receiveSpawnBatch;
      this.handlers[Types.Messages.HEALTH] = this.receiveHealth;
      this.handlers[Types.Messages.CHAT] = this.receiveChat;
      this.handlers[Types.Messages.EQUIP] = this.receiveEquipItem;
      this.handlers[Types.Messages.DROP] = this.receiveDrop;
      this.handlers[Types.Messages.TELEPORT] = this.receiveTeleport;
      this.handlers[Types.Messages.DAMAGE] = this.receiveDamage;
      this.handlers[Types.Messages.POPULATION] = this.receivePopulation;
      this.handlers[Types.Messages.LIST] = this.receiveList;
      this.handlers[Types.Messages.DESTROY] = this.receiveDestroy;
      this.handlers[Types.Messages.KILL] = this.receiveKill;
      this.handlers[Types.Messages.BLINK] = this.receiveBlink;
      this.handlers[Types.Messages.XP] = this.receiveXP;
      this.handlers[Types.Messages.LEVEL] = this.receiveLevel;
      this.handlers[Types.Messages.DATA] = this.receiveData;
      this.handlers[Types.Messages.INVENTORY] = this.receiveInventory;
      this.handlers[Types.Messages.LOOT] = this.receiveLoot;
      this.handlers[Types.Messages.PLAYER_UPDATE] = this.receivePlayerUpdate;
      this.handlers[Types.Messages.PLAYER_ENTER] = this.receivePlayerEnter;
      this.handlers[Types.Messages.PLAYER_EXIT] = this.receivePlayerExit;
      this.handlers[Types.Messages.PLAYERS] = this.receivePlayers;
      this.handlers[Types.Messages.PARTY_JOIN] = this.receivePartyJoin;
      this.handlers[Types.Messages.PARTY_LEAVE] = this.receivePartyLeave;
      this.handlers[Types.Messages.PARTY_INITIAL_JOIN] = this.receivePartyInitialJoin;
      this.handlers[Types.Messages.PARTY_INVITE] = this.receivePartyInvite;
      this.handlers[Types.Messages.PARTY_KICK] = this.receivePartyKick;
      this.handlers[Types.Messages.PARTY_LEADER_CHANGE] = this.receivePartyLeaderChange;

      this.handlers[Types.Messages.GUILD_INVITE] = this.receiveGuildInvite;
      this.handlers[Types.Messages.GUILD_KICK] = this.receiveGuildKick;
      this.handlers[Types.Messages.GUILD_MEMBERS] = this.receiveGuildMembers;
      this.handlers[Types.Messages.GUILD_JOINED] = this.receiveGuildJoined;
      this.handlers[Types.Messages.GUILD_LEFT] = this.receiveGuildLeft;
      this.handlers[Types.Messages.GUILD_ONLINE] = this.receiveGuildOnline;
      this.handlers[Types.Messages.GUILD_OFFLINE] = this.receiveGuildOffline;

      this.handlers[Types.Messages.COMMAND_NOTICE] = this.receiveCommandNotice;
      this.handlers[Types.Messages.COMMAND_ERROR] = this.receiveCommandError;
      this.handlers[Types.Messages.ERROR] = this.receiveError;

      this.chat = new Chat();

      this.useBison = false;
      this.enable();
    },

    setChatChannel: function (channel) {
      this.chat.setChannel(channel);
    },

    error: function () {
      this.chat.insertError(sprintf.apply(null, arguments));
    },

    notice: function () {
      this.chat.insertNotice(sprintf.apply(null, arguments));
    },

    enable: function () {
      this.isListening = true;
    },

    disable: function () {
      this.isListening = false;
    },

    connect: function (dispatcherMode) {
      var url = "ws://" + this.host + ":" + this.port + "/";

      log.info("Trying to connect to server : " + url);

      if (window.MozWebSocket) {
        this.connection = new MozWebSocket(url);
      } else {
        this.connection = new WebSocket(url);
      }

      if (dispatcherMode) {
        this.connection.onmessage = function (e) {
          var reply = JSON.parse(e.data);

          if (reply.status === 'OK') {
            this.trigger("Dispatched", reply.host, reply.port);
          } else if (reply.status === 'FULL') {
            alert("BrowserQuest is currently at maximum player population. Please retry later.");
          } else {
            alert("Unknown error while connecting to BrowserQuest.");
          }
        }.bind(this);
      } else {
        this.connection.onopen = function (e) {
          log.info("Connected to server " + this.host + ":" + this.port);
        }.bind(this);

        this.connection.onmessage = function (e) {
          if (e.data === "go") {
            this.trigger("Connected");
            return;
          }
          if (e.data === 'timeout') {
            this.isTimeout = true;
            return;
          }

          this.receiveMessage(e.data);
        }.bind(this);

        this.connection.onerror = function (e) {
          log.error(e, true);
        };

        this.connection.onclose = function () {
          log.debug("Connection closed");
          $('#container').addClass('error');

          if (this.isTimeout) {
            this.disconnected("You have been disconnected for being inactive for too long");
          } else {
            this.disconnected("The connection to BrowserQuest has been lost");
          }
        }.bind(this);
      }
    },

    sendMessage: function (json) {
      var data;
      if (this.connection.readyState === 1) {
        if (this.useBison) {
          data = BISON.encode(json);
        } else {
          data = JSON.stringify(json);
        }
        this.connection.send(data);

        console.debug("dataOut: " + data);
      }
    },

    receiveMessage: function (message) {
      var data, action;

      if (this.isListening) {
        if (this.useBison) {
          data = BISON.decode(message);
        } else {
          data = JSON.parse(message);
        }

        console.debug("dataIn: " + message);

        if (data instanceof Array) {
          if (data[0] instanceof Array) {
            // Multiple actions received
            this.receiveActionBatch(data);
          } else {
            // Only one action received
            this.receiveAction(data);
          }
        }
      }
    },

    receiveAction: function (data) {
      var action = data[0];
      if (this.handlers[action] && _.isFunction(this.handlers[action])) {
        this.handlers[action].call(this, data);
      } else {
        log.error("Unknown action : " + action);
      }
    },

    receiveActionBatch: function (actions) {
      _.each(actions, function (action) {
        this.receiveAction(action);
      }.bind(this));
    },

    receiveWelcome: function (data) {
      var id = data[1],
        name = data[2],
        x = data[3],
        y = data[4],
        hp = data[5];

      this.trigger("Welcome", id, name, x, y, hp);
    },

    receiveMove: function (data) {
      var id = data[1],
        x = data[2],
        y = data[3];

      if (globalGame.player && id !== globalGame.player.id) {
        var entity = globalGame.getEntityById(id);
        if (entity) {
          if (globalGame.player.isAttackedBy(entity)) {
            globalGame.tryUnlockingAchievement("COWARD");
          }
          entity.disengage();
          entity.idle();
          globalGame.makeCharacterGoTo(entity, x, y);
        } else {
          // maybe it's a player location update
          // check if it's a player entity
          var player = globalGame.getPlayerByID(id);
          if (player) {
            player.setGridPosition(x, y);
          }
        }
      }
    },

    receiveLootMove: function (data) {
      var playerId = data[1],
        itemId = data[2];

      var player, item;
      if (id !== globalGame.player.id) {
        player = globalGame.getEntityById(playerId);
        item = globalGame.getEntityById(itemId);

        if (player && item) {
          globalGame.makeCharacterGoTo(player, item.gridX, item.gridY);
        }
      }
    },

    receiveLoot: function (data) {
      var itemId = data[1];

      var item = globalGame.player.inventory.find(itemId);
      if (!item) {
        console.log("Loot was picked up but couldn't be found in inventory. (%s)", itemId);
        return;
      }

      try {
        globalGame.player.loot(item);
        globalGame.showNotification(item.getLootMessage());

        if (item.type === "armor") {
          globalGame.tryUnlockingAchievement("FAT_LOOT");
        }

        if (item.type === "weapon") {
          globalGame.tryUnlockingAchievement("A_TRUE_WARRIOR");
        }

        if (item.kind === Types.Entities.CAKE) {
          globalGame.tryUnlockingAchievement("FOR_SCIENCE");
        }

        if (item.kind === Types.Entities.FIREPOTION) {
          globalGame.tryUnlockingAchievement("FOXY");
          globalGame.audioManager.playSound("firefox");
        }

        if (Types.isHealingItem(item.kind)) {
          globalGame.audioManager.playSound("heal");
        } else {
          globalGame.audioManager.playSound("loot");
        }

        if (item.wasDropped && !_(item.playersInvolved).include(globalGame.player.id)) {
          globalGame.tryUnlockingAchievement("NINJA_LOOT");
        }
      } catch (e) {
        if (e instanceof Exceptions.LootException) {
          globalGame.showNotification(e.message);
          globalGame.audioManager.playSound("noloot");
        } else {
          throw e;
        }
      }
    },

    receivePartyJoin: function (data) {
      var player = globalGame.getPlayerByID(data[1]);

      globalGame.player.party.joined(player);
    },

    receivePartyInitialJoin: function (data) {
      var leaderID = data[1];
      var membersIDs = data[2];

      globalGame.player.party = new Party(leaderID, membersIDs);
    },

    receivePartyLeave: function (data) {
      var player = globalGame.getPlayerByID(data[1]);

      globalGame.player.party.left(player);
    },

    receivePartyInvite: function (data) {
      var inviter = globalGame.getPlayerByID(data[1]);
      var invitee = globalGame.getPlayerByID(data[2]);

      if (invitee == globalGame.player) {
        if (globalGame.player.party) {
          // already in a party.
          this.notice(
            "You were invited to a party by %s, " + "but you are already in one. ('/leave' to leave it)",
            inviter.name
          );
          return;
        }

        this.notice(
          "You were invited to a party by %s. " + "'/accept %s' to join him.",
          inviter.name,
          inviter.name
        );
        return;
      }

      // this is a message about the party leader inviting someone to the
      // party.
      this.notice(
        "%s invited %s to join your party.",
        inviter.name,
        invitee.name
      );
    },

    receivePartyKick: function (data) {
      var kicker = globalGame.getPlayerByID(data[1]);
      var kicked = globalGame.getPlayerByID(data[2]);

      globalGame.player.party.kicked(kicker, kicked);
    },

    receivePartyLeaderChange: function (data) {
      var player = globalGame.getPlayerByID(data[1]);

      globalGame.player.party.setLeader(player);
    },

    receiveGuildInvite: function (data) {
      var inviterName = data[1];
      var guildName = data[2];

      this.notice(
        "You were invited to join the guild '%s' by %s. '/gaccept %s' to accept.",
        guildName,
        inviterName,
        inviterName
      );
      return;
    },

    receiveGuildKick: function (data) {
      var kickerName = data[1];
      var kickedName = data[2];

      if (kickedName == globalGame.player.name) {
        this.notice(
          "You were kicked from the guild by %s.",
          kickerName
        );
      } else {
        this.notice(
          "%s was kicked from the guild by %s.",
          kickedName,
          kickerName
        );
      }
    },

    receiveGuildJoined: function (data) {
      var playerName = data[1];
      var guildName = data[2];

      if (playerName == globalGame.player.name) {
        this.notice("You have joined the guild %s.", guildName);
      } else {
        this.notice("%s has joined the guild.", playerName);
      }
    },

    receiveGuildLeft: function (data) {
      var playerName = data[1];
      var guildName = data[2];

      if (playerName == globalGame.player.name) {
        this.notice("You have left the guild %s.", guildName);
      } else {
        this.notice("%s has left the guild.", playerName);
      }
    },

    receiveGuildOnline: function (data) {
      var playerName = data[1];

      if (playerName == globalGame.player.name) {
        // don't report the online status to the player itself
        return;
      }

      this.notice("%s has come online.", playerName);
    },

    receiveGuildOffline: function (data) {
      var playerName = data[1];

      if (playerName == globalGame.player.name) {
        // don't report the online status to the player itself
        return;
      }

      this.notice("%s went offline.", playerName);
    },

    receiveGuildMembers: function (data) {
      // @TODO: move to a config
      var rankToTitle = {0: "Leader", 1: "Member", 2: "Officer"};

      var members = data[1];
      this.notice("Members of %s:", globalGame.player.guild.name);
      for (var i in members) {
        this.notice(
          "%s (%s)%s",
          members[i].name,
          rankToTitle[members[i].rank],
          members[i].online ? " - Online" : ""
        );
      }
    },

    receiveCommandNotice: function (data) {
      var noticeMessage = data[1];
      this.notice(noticeMessage);
    },

    receiveCommandError: function (data) {
      var errorMessage = data[1];
      this.error(errorMessage);
    },

    receiveError: function (data) {
      var errorMessage = data[1];
      this.error(errorMessage);
    },

    receiveAttack: function (data) {
      var attackerId = data[1],
        targetId = data[2];

      var attacker = globalGame.getEntityById(attackerId),
        target = globalGame.getEntityById(targetId);

      if (attacker && target && attacker.id !== globalGame.player.id) {
        log.debug(attacker.id + " attacks " + target.id);

        if (attacker && target instanceof Player && target.id !== globalGame.player.id && target.target && target.target.id === attacker.id && attacker.getDistanceToEntity(target) < 3) {
          // delay to prevent other players attacking mobs 
          // from ending up on the same tile as they walk 
          // towards each other.
          setTimeout(function () {
            globalGame.createAttackLink(attacker, target);
          }, 200);
        } else {
          globalGame.createAttackLink(attacker, target);
        }
      }
    },

    receivePlayers: function (data) {
      var playersData = data[1];
      for (var i in playersData) {
        this.handlePlayerEnter(playersData[i]);
      }
    },

    receivePlayerEnter: function (data) {
      this.handlePlayerEnter(data[1]);
    },

    receivePlayerUpdate: function (data) {
      var playerData = data[1];
      var player = globalGame.getPlayerByID(playerData.id);
      if (!player || player.id == globalGame.player.id) {
        // irrelevant update
        return;
      }
    
      $.extend(player, playerData.data);
    },

    handlePlayerEnter: function (playerData) {
      var player = globalGame.getPlayerByID(playerData.id);
      if (player) {
        // already exists - skip it
        return;
      }

      player = EntityFactory.createEntity(playerData.kind, playerData.id, playerData.name);
      $.extend(player, playerData.data);
      globalGame.addPlayer(player);
    },

    receivePlayerExit: function (data) {
      var id = data[1];

      globalGame.removePlayer(id);
    },

    receiveSpawn: function (data) {
      var id = data[1],
        kind = data[2],
        x = data[3],
        y = data[4];

      if (Types.isSpell(kind)) {
        //@TODO: handle properly
        return;

        var spell = EntityFactory.createEntity(kind, id);

      } else if (Types.isItem(kind)) {
        var item = EntityFactory.createEntity(kind, id);

        log.info("Spawned " + Types.getKindAsString(item.kind) + " (" + item.id + ") at " + x + ", " + y);
        globalGame.addItem(item, x, y);
      } else if (Types.isChest(kind)) {
        var chest = EntityFactory.createEntity(kind, id);

        log.info("Spawned chest (" + chest.id + ") at " + x + ", " + y);
        chest.setSprite(globalGame.sprites[chest.getSpriteName()]);
        chest.setGridPosition(x, y);
        chest.setAnimation("idle_down", 150);
        globalGame.addEntity(chest, x, y);
      } else {
        var name, orientation, targetId, weapon, armor, hp, maxHP;

        hp = data[5];
        maxHP = data[6];
        orientation = data[7];
        targetId = data[8];

        var character;
        if (Types.isPlayer(kind)) {
          name = data[9];
          armor = data[10];
          weapon = data[11];

          // get existing player entity
          character = globalGame.getPlayerByID(id);
          character.reset();
        } else {
          character = EntityFactory.createEntity(kind, id, name);
        }

        character.hp = hp;
        character.maxHP = maxHP;

        if (character instanceof Player) {
          character.equipWeapon(weapon);
          character.equipArmor(armor);
        }

        if (!globalGame.entityIdExists(character.id)) {
          try  {
            if (character.id !== globalGame.player.id) {
              var kindString = Types.getKindAsString(character.skin);
              character.setSprite(globalGame.sprites[kindString]);
              character.setGridPosition(x, y);
              character.setOrientation(orientation);
              character.idle();

              globalGame.addEntity(character);

              log.info("Spawned " + Types.getKindAsString(character.kind) + " (" + character.id + ") at " + character.gridX + ", " + character.gridY);

              if (character instanceof Mob) {
                if (targetId) {
                  var player = globalGame.getEntityById(targetId);
                  if (player) {
                    globalGame.createAttackLink(character, player);
                  }
                }
              }
            }
          } catch (e) {
            log.error("ReceiveSpawn failed. Error: " + e);
            log.error(e.stack);
          }
        } else {
          log.debug("Character " + character.id + " already exists. Don't respawn.");
        }
      }
    },

    receiveDespawn: function (data) {
      var id = data[1];

      var entity = globalGame.getEntityById(id, true);
      if (entity) {
        entity.removed = true;

        log.info("Despawning " + Types.getKindAsString(entity.kind) + " (" + entity.id + ")");

        if (entity.gridX === globalGame.previousClickPosition.x && entity.gridY === globalGame.previousClickPosition.y) {
          globalGame.previousClickPosition = {};
        }

        if (entity instanceof SpellEffect) {
          globalGame.removeSpellEffect(entity);
        } else if (entity instanceof Item) {
          globalGame.removeItem(entity);
        } else if (entity instanceof Character) {
          entity.forEachAttacker(function (attacker) {
            if (attacker.canReachTarget()) {
              attacker.hit();
            }
          });
          entity.die();
        } else if (entity instanceof Chest) {
          entity.open();
        }

        entity.clean();
      }
    },

    receiveHealth: function (data) {
      var entityId = data[1],
        hp = data[2],
        maxHP = data[3],
        isRegen = data[4] ? true : false;

      var entity = globalGame.getEntityById(entityId);
      if (entity) {
        var diff = hp - entity.hp;

        entity.maxHP = maxHP;
        entity.hp = hp;

        if (entityId == globalGame.player.id) {
          var player = globalGame.player,
            isHurt = diff < 0;

          if (player && !player.isDead && !player.invincible) {
            //if (player.hp <= 0) {
            //player.die();
            //}
            if (isHurt) {
              player.hurt();
              globalGame.infoManager.addDamageInfo(diff, player.x, player.y - 15, "received");
              globalGame.audioManager.playSound("hurt");
              globalGame.storage.addDamage(-diff);
              globalGame.tryUnlockingAchievement("MEATSHIELD");
              globalGame.trigger("Hurt");
            } else if (!isRegen) {
              globalGame.infoManager.addDamageInfo("+" + diff, player.x, player.y - 15, "healed");
            }
          }
        }
      }
    },

    receiveChat: function (data) {
      var playerID = data[1],
        message = data[2],
        channel = data[3],
        playerName = data[4];

      if (channel == "say" || channel == "yell") {
        var player = globalGame.getPlayerByID(playerID);
        globalGame.createBubble(playerID, message);
        globalGame.assignBubbleTo(player);
      }

      globalGame.audioManager.playSound("chat");

      var namePrefix = "";
      if (channel == "party" && globalGame.player.party && globalGame.player.party.isLeader(player)) {
        namePrefix = "\u2694 ";
      }

      this.chat.insertMessage(player, namePrefix + playerName, message, channel);
    },

    receiveEquipItem: function (data) {
      var playerId = data[1],
        itemKind = data[2];

      var player = globalGame.getEntityById(playerId),
        itemName = Types.getKindAsString(itemKind);

      if (player) {
        player.equip(itemKind);
      }
    },

    receiveDrop: function (data) {
      var entityId = data[1],
        id = data[2],
        kind = data[3];

      var item = EntityFactory.createEntity(kind, id);
      item.wasDropped = true;
      item.playersInvolved = data[4];

      var pos = data[5];
      if (!pos) {
        pos = globalGame.getDeadMobPosition(entityId);
      }

      globalGame.addItem(item, pos.x, pos.y);
      globalGame.updateCursor();
    },

    receiveTeleport: function (data) {
      var id = data[1],
        x = data[2],
        y = data[3];

      if (id !== globalGame.player.id) {
        var entity = null,
          currentOrientation;

        entity = globalGame.getEntityById(id);
        if (entity) {
          currentOrientation = entity.orientation;

          globalGame.makeCharacterTeleportTo(entity, x, y);
          entity.setOrientation(currentOrientation);

          entity.forEachAttacker(function (attacker) {
            attacker.disengage();
            attacker.idle();
            attacker.stop();
          });
        }
      }
    },

    receiveDamage: function (data) {
      var entityId = data[1],
        points = data[2],
        attackerId = data[3];

      var entity = globalGame.getEntityById(entityId, true);
      if (attackerId == globalGame.player.id) {
        if (entity) {
          globalGame.infoManager.addDamageInfo(points, entity.x, entity.y - 15, "inflicted");
        }
      } else if (entityId == globalGame.player.id) {
        globalGame.infoManager.addDamageInfo(-points, globalGame.player.x, globalGame.player.y - 15, "received");
      }
    },

    receivePopulation: function (data) {
      var worldPlayers = data[1],
        totalPlayers = data[2];

      var setWorldPlayersString = function (string) {
        $("#instance-population").find("span:nth-child(2)").text(string);
        $("#playercount").find("span:nth-child(2)").text(string);
      },
        setTotalPlayersString = function (string) {
          $("#world-population").find("span:nth-child(2)").text(string);
        };

      $("#playercount").find("span.count").text(worldPlayers);

      $("#instance-population").find("span").text(worldPlayers);
      if (worldPlayers == 1) {
        setWorldPlayersString("player");
      } else {
        setWorldPlayersString("players");
      }

      $("#world-population").find("span").text(totalPlayers);
      if (totalPlayers == 1) {
        setTotalPlayersString("player");
      } else {
        setTotalPlayersString("players");
      }
    },

    receiveKill: function (data) {
      var kind = data[1];
      var mobName = Types.getKindAsString(kind);

      if (mobName === 'skeleton2') {
        mobName = 'greater skeleton';
      }

      if (mobName === 'eye') {
        mobName = 'evil eye';
      }

      if (mobName === 'deathknight') {
        mobName = 'death knight';
      }

      if (mobName === 'boss') {
        globalGame.showNotification("You killed the skeleton king");
      } else {
        if (_.include(['a', 'e', 'i', 'o', 'u'], mobName[0])) {
          globalGame.showNotification("You killed an " + mobName);
        } else {
          globalGame.showNotification("You killed a " + mobName);
        }
      }

      globalGame.storage.incrementTotalKills();
      globalGame.tryUnlockingAchievement("HUNTER");

      if (kind === Types.Entities.RAT) {
        globalGame.storage.incrementRatCount();
        globalGame.tryUnlockingAchievement("ANGRY_RATS");
      }

      if (kind === Types.Entities.SKELETON || kind === Types.Entities.SKELETON2) {
        globalGame.storage.incrementSkeletonCount();
        globalGame.tryUnlockingAchievement("SKULL_COLLECTOR");
      }

      if (kind === Types.Entities.BOSS) {
        globalGame.tryUnlockingAchievement("HERO");
      }
    },

    receiveList: function (data) {
      data.shift();

      this.trigger("EntityList", data);
    },

    receiveDestroy: function (data) {
      var id = data[1];

      var entity = globalGame.getEntityById(id, true);
      if (entity) {
        if (entity instanceof Item) {
          globalGame.removeItem(entity);
        } else {
          globalGame.removeEntity(entity);
        }
        log.debug("Entity was destroyed: " + entity.id);
      }
    },

    receiveXP: function (data) {
      var xp = data[1],
        maxXP = data[2],
        gainedXP = data[3];

      var player = globalGame.player;
      player.xp = xp;
      if (gainedXP != 0) {
        globalGame.showNotification("You " + (gainedXP > 0 ? "gained" : "lost") + " " + gainedXP + " XP");
        globalGame.infoManager.addDamageInfo((gainedXP > 0 ? "+" : "-") + gainedXP + " XP", player.x + 5, player.y - 15, "xp");
      }

      if (!player.maxXP || player.maxXP != maxXP) {
        player.maxXP = maxXP;
      }
    },

    receiveBlink: function (data) {
      var id = data[1];

      var item = globalGame.getEntityById(id);
      if (item) {
        item.blink(150);
      }
    },

    receiveLevel: function (data) {
      var level = data[1];

      globalGame.player.level = level;
    },

    receiveData: function (data) {
      var dataObject = data[1];

      globalGame.player.loadFromObject(dataObject);
    },

    receiveInventory: function (data) {
      var dataObject = data[1];

      globalGame.player.loadInventory(dataObject);
    },

    disconnected: function (message) {
      if (globalGame.player) {
        globalGame.player.die();
      }
      globalGame.disconnected(message);
    },

    sendInventory: function (inventory) {
      this.sendMessage([Types.Messages.INVENTORY,
        inventory.serialize()
      ]);
    },

    sendInventoryItem: function (inventoryItem) {
      this.sendMessage([Types.Messages.INVENTORYITEM,
        inventoryItem.serialize()
      ]);
    },

    sendInventorySwap: function (first, second) {
      this.sendMessage([Types.Messages.INVENTORYSWAP,
        first,
        second
      ]);
    },

    sendUseItem: function (item, target) {
      var message = [Types.Messages.USEITEM,
        item.id
      ];
      if (target) {
        message.push(target.id);
      }

      this.sendMessage(message);
    },

    sendUseSpell: function (spell, target, orientation, trackingId) {
      var message = [Types.Messages.USESPELL,
        spell.kind
      ];

      var targetId = null;
      if (target) {
        targetId = target.id;
      }
      message.push(targetId);
      message.push(orientation);
      message.push(trackingId);

      this.sendMessage(message);
    },

    sendSkillbar: function (skillbar) {
      this.sendMessage([Types.Messages.SKILLBAR,
        skillbar.serialize()
      ]);
    },

    sendThrowItem: function (item, target) {
      var message = [Types.Messages.THROWITEM,
        item.id
      ];
      if (target) {
        message.push(target.id);
      }

      this.sendMessage(message);
    },

    sendHello: function (playerName, isResurrection) {
      this.sendMessage([Types.Messages.HELLO,
        playerName
      ]);
    },

    sendResurrect: function () {
      this.sendMessage([Types.Messages.RESURRECT]);
    },

    sendMove: function (x, y) {
      this.sendMessage([Types.Messages.MOVE,
        x,
        y
      ]);
    },

    sendLootMove: function (item, x, y) {
      this.sendMessage([Types.Messages.LOOTMOVE,
        x,
        y,
        item.id
      ]);
    },

    sendAggro: function (mob) {
      this.sendMessage([Types.Messages.AGGRO,
        mob.id
      ]);
    },

    sendAttack: function (mob) {
      this.sendMessage([Types.Messages.ATTACK,
        mob.id
      ]);
    },

    sendHit: function (mob) {
      this.sendMessage([Types.Messages.HIT,
        mob.id
      ]);
    },

    sendHurt: function (mob) {
      this.sendMessage([Types.Messages.HURT,
        mob.id
      ]);
    },

    sendChat: function (text, channel) {
      if (!channel) {
        channel = this.chat.getChannel();
      }
      this.sendMessage([Types.Messages.CHAT,
        text,
        channel
      ]);
    },

    sendPartyAccept: function (inviterId) {
      this.sendMessage([Types.Messages.PARTY_ACCEPT,
        inviterId
      ]);
    },

    sendPartyLeaderChange: function (playerID) {
      this.sendMessage([Types.Messages.PARTY_LEADER_CHANGE,
        playerID
      ]);
    },

    sendPartyLeave: function () {
      this.sendMessage([Types.Messages.PARTY_LEAVE]);
    },

    sendPartyInvite: function (playerId) {
      this.sendMessage([Types.Messages.PARTY_INVITE,
        globalGame.player.id,
        playerId
      ]);
    },

    sendPartyKick: function (playerId) {
      this.sendMessage([Types.Messages.PARTY_KICK,
        playerId
      ]);
    },

    sendGuildCreate: function (name) {
      this.sendMessage([Types.Messages.GUILD_CREATE,
        name
      ]);
    },

    sendGuildAccept: function (name) {
      this.sendMessage([Types.Messages.GUILD_ACCEPT,
        name
      ]);
    },

    sendGuildLeaderChange: function (name) {
      this.sendMessage([Types.Messages.GUILD_LEADER_CHANGE,
        name
      ]);
    },

    sendGuildQuit: function () {
      this.sendMessage([Types.Messages.GUILD_QUIT]);
    },

    sendGuildInvite: function (name) {
      this.sendMessage([Types.Messages.GUILD_INVITE,
        name
      ]);
    },

    sendGuildKick: function (name) {
      this.sendMessage([Types.Messages.GUILD_KICK,
        name
      ]);
    },

    sendGuildOnline: function () {
      this.sendMessage([Types.Messages.GUILD_ONLINE]);
    },

    sendGuildMembers: function () {
      this.sendMessage([Types.Messages.GUILD_MEMBERS]);
    },

    sendLoot: function (item) {
      this.sendMessage([Types.Messages.LOOT,
        item.id
      ]);
    },

    sendTeleport: function (x, y) {
      this.sendMessage([Types.Messages.TELEPORT,
        x,
        y
      ]);
    },

    sendWho: function (ids) {
      ids.unshift(Types.Messages.WHO);
      this.sendMessage(ids);
    },

    sendZone: function () {
      this.sendMessage([Types.Messages.ZONE]);
    },

    sendOpen: function (chest) {
      this.sendMessage([Types.Messages.OPEN,
        chest.id
      ]);
    },

    sendCheck: function (id) {
      this.sendMessage([Types.Messages.CHECK,
        id
      ]);
    }
  });

  return GameClient;
});
