library gameclient;

import "dart:convert";
import "dart:html";

import "base.dart";
import "character.dart";
import "chat.dart";
import "chest.dart";
import "damageinfo.dart";
import "entityfactory.dart";
import "game.dart";
import "inventoryitem.dart";
import "item.dart";
import "mob.dart";
import "party.dart";
import "player.dart";
import "spell.dart";
import "spelleffect.dart";
import "../shared/dart/gametypes.dart";

class GameClient extends Base {

  String host;
  int port;
  Chat chat;
  bool isListening = false;
  bool isTimeout = false;
  WebSocket connection;

  GameClient() {
    this.chat = new Chat();
    this.enable();

    this.on(Message.WELCOME, (data) {
      var id = data[1],
        name = data[2],
        x = data[3],
        y = data[4],
        hp = data[5];

      this.trigger("Welcome", [id, name, x, y, hp]);
    });

    this.on(Message.MOVE, (data) {
      var id = data[1],
        x = data[2],
        y = data[3];

      if (Game.player != null && id != Game.player.id) {
        var entity = Game.getEntityById(id);
        if (entity) {
          if (Game.player.isAttackedBy(entity)) {
            Game.tryUnlockingAchievement("COWARD");
          }
          entity.disengage();
          entity.idle();
          Game.makeCharacterGoTo(entity, x, y);
        } else {
          // maybe it's a player location update
          // check if it's a player entity
          Player player = Game.getPlayerByID(id);
          if (player != null) {
            player.setGridPosition(x, y);
          }
        }
      }
    });

    this.on(Message.LOOTMOVE, (data) {
      int playerId = data[1];
      int itemId = data[2];

      Player player;
      Item item;
      if (playerId != Game.player.id) {
        player = Game.getEntityById(playerId);
        item = Game.getEntityById(itemId);

        if (player != null && item != null) {
          Game.makeCharacterGoTo(player, item.gridX, item.gridY);
        }
      }
    });

    this.on(Message.LOOT, (data) {
      var itemId = data[1];

      var item = Game.player.inventory.find(itemId);
      if (!item) {
        window.console.log("Loot was picked up but couldn't be found in inventory. (${itemId})");
        return;
      }

      try {
        Game.player.loot(item);
        Game.showNotification(item.getLootMessage());

        if (item.type == "armor") {
          Game.tryUnlockingAchievement("FAT_LOOT");
        }

        if (item.type == "weapon") {
          Game.tryUnlockingAchievement("A_TRUE_WARRIOR");
        }

        if (item.kind == Entities.CAKE) {
          Game.tryUnlockingAchievement("FOR_SCIENCE");
        }

        if (item.kind == Entities.FIREPOTION) {
          Game.tryUnlockingAchievement("FOXY");
          Game.audioManager.playSound("firefox");
        }

        if (Types.isHealingItem(item.kind)) {
          Game.audioManager.playSound("heal");
        } else {
          Game.audioManager.playSound("loot");
        }

        if (item.wasDropped && !item.playersInvolved.contains(Game.player.id)) {
          Game.tryUnlockingAchievement("NINJA_LOOT");
        }
      } catch (e) {
        // TODO: find a better way to do this and remove the comments
        /*if (e instanceof Exceptions.LootException) {*/
          /*Game.showNotification(e.message);*/
          /*Game.audioManager.playSound("noloot");*/
        /*} else {*/
          throw e;
        /*}*/
      }
    });

    this.on(Message.PARTY_JOIN, (data) {
      Player player = Game.getPlayerByID(data[1]);

      Game.player.party.joined(player);
    });

    this.on(Message.PARTY_INITIAL_JOIN, (data) {
      var leaderID = data[1];
      var membersIDs = data[2];

      Game.player.party = new Party(leaderID, membersIDs);
    });

    this.on(Message.PARTY_LEAVE, (data) {
      Player player = Game.getPlayerByID(data[1]);

      Game.player.party.left(player);
    });

    this.on(Message.PARTY_INVITE, (data) {
      var inviter = Game.getPlayerByID(data[1]);
      var invitee = Game.getPlayerByID(data[2]);

      if (invitee == Game.player) {
        if (Game.player.party) {
          // already in a party.
          this.notice("You were invited to a party by ${inviter.name} but you are already in one. ('/leave' to leave it)");
          return;
        }

        this.notice("You were invited to a party by ${inviter.name}. '/accept ${inviter.name}' to join him.");
        return;
      }

      // this is a message about the party leader inviting someone to the
      // party.
      this.notice("${inviter.name} invited ${invitee.name} to join your party.");
    });

    this.on(Message.PARTY_KICK, (data) {
      var kicker = Game.getPlayerByID(data[1]);
      var kicked = Game.getPlayerByID(data[2]);

      Game.player.party.kicked(kicker, kicked);
    });

    this.on(Message.PARTY_LEADER_CHANGE, (data) {
      Player player = Game.getPlayerByID(data[1]);

      Game.player.party.setLeader(player);
    });

    this.on(Message.GUILD_INVITE, (data) {
      var inviterName = data[1];
      String guildName = data[2];

      this.notice("You were invited to join the guild '${guildName}' by ${inviterName}. '/gaccept ${inviterName}' to accept.");
      return;
    });

    this.on(Message.GUILD_KICK, (data) {
      var kickerName = data[1];
      var kickedName = data[2];

      if (kickedName == Game.player.name) {
        this.notice("You were kicked from the guild by ${kickerName}.");
      } else {
        this.notice("${kickedName} was kicked from the guild by ${kickerName}.");
      }
    });

    this.on(Message.GUILD_JOINED, (data) {
      String playerName = data[1];
      String guildName = data[2];

      if (playerName == Game.player.name) {
        this.notice("You have joined the guild ${guildName}.");
      } else {
        this.notice("${playerName} has joined the guild.");
      }
    });

    this.on(Message.GUILD_LEFT, (data) {
      String playerName = data[1];
      String guildName = data[2];

      if (playerName == Game.player.name) {
        this.notice("You have left the guild ${guildName}.");
      } else {
        this.notice("${playerName} has left the guild.");
      }
    });

    this.on(Message.GUILD_ONLINE, (data) {
      String playerName = data[1];

      if (playerName == Game.player.name) {
        // don't report the online status to the player itself
        return;
      }

      this.notice("${playerName} has come online.");
    });

    this.on(Message.GUILD_OFFLINE, (data) {
      String playerName = data[1];

      if (playerName == Game.player.name) {
        // don't report the online status to the player itself
        return;
      }

      this.notice("${playerName} went offline.");
    });

    this.on(Message.GUILD_MEMBERS, (data) {
      // @TODO: move to a config
      var rankToTitle = {0: "Leader", 1: "Member", 2: "Officer"};

      var members = data[1];
      this.notice("Members of ${Game.player.guild.name}:");
      for (var i in members) {
        this.notice("${members[i].name} (${rankToTitle[members[i].rank]})" + (members[i].online ? " - Online" : ""));
      }
    });

    this.on(Message.COMMAND_NOTICE, (data) {
      var noticeMessage = data[1];
      this.notice(noticeMessage);
    });

    this.on(Message.COMMAND_ERROR, (data) {
      var errorMessage = data[1];
      this.error(errorMessage);
    });

    this.on(Message.ERROR, (data) {
      var errorMessage = data[1];
      this.error(errorMessage);
    });

    this.on(Message.ATTACK, (data) {
      var attackerId = data[1],
        targetId = data[2];

      var attacker = Game.getEntityById(attackerId),
        target = Game.getEntityById(targetId);

      if (attacker && target && attacker.id != Game.player.id) {
        window.console.debug(attacker.id + " attacks " + target.id);

        if (attacker && target is Player && target.id != Game.player.id && target.target && target.target.id == attacker.id && attacker.getDistanceToEntity(target) < 3) {
          // delay to prevent other players attacking mobs 
          // from ending up on the same tile as they walk 
          // towards each other.
          setTimeout(() {
            Game.createAttackLink(attacker, target);
          }, 200);
        } else {
          Game.createAttackLink(attacker, target);
        }
      }
    });

    this.on(Message.PLAYERS, (data) {
      var playersData = data[1];
      for (var i in playersData) {
        this.handlePlayerEnter(playersData[i]);
      }
    });

    this.on(Message.PLAYER_ENTER, (data) {
      this.handlePlayerEnter(data[1]);
    });

    this.on(Message.PLAYER_UPDATE, (data) {
      var playerData = data[1];
      Player player = Game.getPlayerByID(playerData.id);
      if (player == null || player.id == Game.player.id) {
        // irrelevant update
        return;
      }
    
      player.loadFromObject(playerData.data);
    });

    this.on(Message.PLAYER_EXIT, (data) {
      var id = data[1];

      Game.removePlayer(id);
    });

    this.on(Message.SPAWN, (data) {
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

        window.console.info("Spawned " + Types.getKindAsString(item.kind) + " (" + item.id + ") at " + x + ", " + y);
        Game.addItem(item, x, y);
      } else if (Types.isChest(kind)) {
        var chest = EntityFactory.createEntity(kind, id);

        window.console.info("Spawned chest (" + chest.id + ") at " + x + ", " + y);
        chest.setSprite(Game.sprites[chest.getSpriteName()]);
        chest.setGridPosition(x, y);
        chest.setAnimation("idle_down", 150);
        Game.addEntity(chest, x, y);
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
          character = Game.getPlayerByID(id);
          character.reset();
        } else {
          character = EntityFactory.createEntity(kind, id, name);
        }

        character.hp = hp;
        character.maxHP = maxHP;

        if (character is Player) {
          character.equipWeapon(weapon);
          character.equipArmor(armor);
        }

        if (!Game.entityIdExists(character.id)) {
          try {
            if (character.id != Game.player.id) {
              var kindString = Types.getKindAsString(character.skin);
              character.setSprite(Game.sprites[kindString]);
              character.setGridPosition(x, y);
              character.setOrientation(orientation);
              character.idle();

              Game.addEntity(character);

              window.console.info("Spawned " + Types.getKindAsString(character.kind) + " (" + character.id + ") at " + character.gridX + ", " + character.gridY);

              if (character is Mob) {
                if (targetId) {
                  Player player = Game.getEntityById(targetId);
                  if (player != null) {
                    Game.createAttackLink(character, player);
                  }
                }
              }
            }
          } catch (e) {
            window.console.error("ReceiveSpawn failed. Error: " + e);
            window.console.error(e.stack);
          }
        } else {
          window.console.debug("Character " + character.id + " already exists. Don't respawn.");
        }
      }
    });

    this.on(Message.DESPAWN, (data) {
      var id = data[1];

      var entity = Game.getEntityById(id, true);
      if (entity) {
        entity.removed = true;

        window.console.info("Despawning " + Types.getKindAsString(entity.kind) + " (" + entity.id + ")");

        if (entity.gridX == Game.previousClickPosition.x && entity.gridY == Game.previousClickPosition.y) {
          Game.previousClickPosition = {};
        }

        if (entity is SpellEffect) {
          Game.removeSpellEffect(entity);
        } else if (entity is Item) {
          Game.removeItem(entity);
        } else if (entity is Character) {
          entity.forEachAttacker((attacker) {
            if (attacker.canReachTarget()) {
              attacker.hit();
            }
          });
          entity.die();
        } else if (entity is Chest) {
          entity.open();
        }

        entity.clean();
      }
    });

    this.on(Message.HEALTH, (data) {
      var entityId = data[1],
        hp = data[2],
        maxHP = data[3],
        isRegen = data[4] ? true : false;

      var entity = Game.getEntityById(
        entityId, 
        /* silence errors */ false,
        /* load player */ true 
      );
      if (entity) {
        var diff = hp - entity.hp;

        entity.maxHP = maxHP;
        entity.hp = hp;

        if (entityId == Game.player.id) {
          Player player = Game.player;
          bool isHurt = diff < 0;

          if (player != null && !player.isDead && !player.invincible) {
            //if (player.hp <= 0) {
            //player.die();
            //}
            if (isHurt) {
              player.hurt();
              Game.infoManager.addInfo(new ReceivedDamageInfo(diff, player.x, player.y - 15));
              Game.audioManager.playSound("hurt");
              Game.storage.addDamage(-diff);
              Game.tryUnlockingAchievement("MEATSHIELD");
              Game.trigger("Hurt");
            } else if (!isRegen) {
              Game.infoManager.addInfo(new HealedDamageInfo("+" + diff, player.x, player.y - 15));
            }
          }
        }
      }
    });

    this.on(Message.CHAT, (data) {
      var playerID = data[1],
        message = data[2],
        channel = data[3],
        playerName = data[4];

      Player player = Game.getPlayerByID(playerID);

      if (channel == "say" || channel == "yell") {
        Game.createBubble(playerID, message);
        Game.assignBubbleTo(player);
      }

      Game.audioManager.playSound("chat");

      var namePrefix = "";
      if (channel == "party" && Game.player.party && Game.player.party.isLeader(player)) {
        namePrefix = "\u2694 ";
      }

      this.chat.insertMessage(message, channel, player, namePrefix);
    });

    this.on(Message.EQUIP, (data) {
      var playerId = data[1],
        itemKind = data[2];

      var player = Game.getEntityById(playerId),
        itemName = Types.getKindAsString(itemKind);

      if (player != null) {
        player.equip(itemKind);
      }
    });

    this.on(Message.DROP, (data) {
      var entityId = data[1],
        id = data[2],
        kind = data[3];

      var item = EntityFactory.createEntity(kind, id);
      item.wasDropped = true;
      item.playersInvolved = data[4];

      var pos = data[5];
      if (!pos) {
        pos = Game.getDeadMobPosition(entityId);
      }

      Game.addItem(item, pos.x, pos.y);
      Game.updateCursor();
    });

    this.on(Message.TELEPORT, (data) {
      var id = data[1],
        x = data[2],
        y = data[3];

      if (id != Game.player.id) {
        var entity = null,
          currentOrientation;

        entity = Game.getEntityById(id);
        if (entity) {
          currentOrientation = entity.orientation;

          Game.makeCharacterTeleportTo(entity, x, y);
          entity.setOrientation(currentOrientation);

          entity.forEachAttacker((attacker) {
            attacker.disengage();
            attacker.idle();
            attacker.stop();
          });
        }
      }
    });

    this.on(Message.DAMAGE, (data) {
      var entityId = data[1],
        points = data[2],
        attackerId = data[3];

      var entity = Game.getEntityById(entityId, true);
      if (attackerId == Game.player.id) {
        if (entity) {
          Game.infoManager.addInfo(new InflictedDamageInfo(points, entity.x, entity.y - 15));
        }
      } else if (entityId == Game.player.id) {
        Game.infoManager.addInfo(new ReceivedDamageInfo(-points, Game.player.x, Game.player.y - 15));
      }
    });

    this.on(Message.POPULATION, (data) {
      var worldPlayers = data[1],
        totalPlayers = data[2];

      var setWorldPlayersString = (string) {
        $("#instance-population").find("span:nth-child(2)").text(string);
        $("#playercount").find("span:nth-child(2)").text(string);
      },
        setTotalPlayersString = (string) {
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
    });

    this.on(Message.KILL, (data) {
      var kind = data[1];
      var mobName = Types.getKindAsString(kind);

      if (mobName == 'skeleton2') {
        mobName = 'greater skeleton';
      }

      if (mobName == 'eye') {
        mobName = 'evil eye';
      }

      if (mobName == 'deathknight') {
        mobName = 'death knight';
      }

      if (mobName == 'boss') {
        Game.showNotification("You killed the skeleton king");
      } else {
        if (_.include(['a', 'e', 'i', 'o', 'u'], mobName[0])) {
          Game.showNotification("You killed an " + mobName);
        } else {
          Game.showNotification("You killed a " + mobName);
        }
      }

      Game.storage.incrementTotalKills();
      Game.tryUnlockingAchievement("HUNTER");

      if (kind == Entities.RAT) {
        Game.storage.incrementRatCount();
        Game.tryUnlockingAchievement("ANGRY_RATS");
      }

      if (kind == Entities.SKELETON || kind == Entities.SKELETON2) {
        Game.storage.incrementSkeletonCount();
        Game.tryUnlockingAchievement("SKULL_COLLECTOR");
      }

      if (kind == Entities.BOSS) {
        Game.tryUnlockingAchievement("HERO");
      }
    });

    this.on(Message.DEFEATED, (data) {
      var actualData = data[1];
      this.notice("*** ${actualData.attackerName} has defeated ${actualData.victimName} (${actualData.x}, ${actualData.y}) ***");
    });

    this.on(Message.LIST, (data) {
      data.shift();

      this.trigger("EntityList", [data]);
    });

    this.on(Message.DESTROY, (data) {
      var id = data[1];

      var entity = Game.getEntityById(id, true);
      if (entity) {
        if (entity is Item) {
          Game.removeItem(entity);
        } else {
          Game.removeEntity(entity);
        }
        window.console.debug("Entity was destroyed: " + entity.id);
      }
    });

    this.on(Message.XP, (data) {
      var xp = data[1],
        maxXP = data[2],
        gainedXP = data[3];

      Player player = Game.player;
      player.xp = xp;
      if (gainedXP != 0) {
        Game.showNotification("You " + (gainedXP > 0 ? "gained" : "lost") + " " + gainedXP + " XP");
        Game.infoManager.addInfo(new XPInfo((gainedXP > 0 ? "+" : "-") + gainedXP + " XP", player.x + 5, player.y - 15));
      }

      if (!player.maxXP || player.maxXP != maxXP) {
        player.maxXP = maxXP;
      }
    });

    this.on(Message.BLINK, (data) {
      var id = data[1];

      var item = Game.getEntityById(id);
      if (item) {
        item.blink(150);
      }
    });

    this.on(Message.LEVEL, (data) {
      var level = data[1];

      Game.player.level = level;
    });

    this.on(Message.DATA, (data) {
      var dataObject = data[1];

      Game.player.loadFromObject(dataObject);
    });

    this.on(Message.INVENTORY, (data) {
      var dataObject = data[1];

      Game.player.loadInventory(dataObject);
    });
  }

  void enable() {
    this.isListening = true;
  }

  void disable() {
    this.isListening = false;
  }

  void error(String message) {
    this.chat.insertError(message);
  }

  void notice(String message) {
    this.chat.insertNotice(message);
  }

  void connect(bool dispatcherMode) {
    String url = "ws://${this.host}:${this.port}/";
    window.console.info("Trying to connect to server '${url}'");
    this.connection = new WebSocket(url);
    if (dispatcherMode) {
      this.connection.onMessage.listen((MessageEvent e) {
        var reply = JSON.decode(e.data);
        if (reply.status == "OK") {
          this.trigger("Dispatched", [reply.host, reply.port]);
        } else if (reply.status == "FULL") {
          window.alert("BrowserQuest is currently at maximum player population. Please retry later.");
        } else {
          window.alert("Unknown error while connecting to BrowserQuest.");
        }
      });
      return;
    }

    this.connection.onOpen.listen((MessageEvent e) {
      window.console.info("Connected to server " + this.host + ":" + this.port);
    });

    this.connection.onMessage.listen((MessageEvent e) {
      if (e.data == "go") {
        this.trigger("Connected");
        return;
      }
      if (e.data == 'timeout') {
        this.isTimeout = true;
        return;
      }

      this.receiveMessage(e.data);
    });

    this.connection.onError.listen((MessageEvent e) {
      window.console.error(e, true);
    });

    this.connection.onClose.listen((MessageEvent e) {
      window.console.debug("Connection closed");
      document.querySelector("#container").classes.add("error");

      if (this.isTimeout) {
        this.disconnected("You have been disconnected for being inactive for too long");
      } else {
        this.disconnected("The connection to BrowserQuest has been lost");
      }
    });
  }

  void sendMessage(json) {
    if (this.connection == null || this.connection.readyState != WebSocket.OPEN) {
      throw "Unable to send message - WebSocket is not connected.";
    }

    var data = JSON.encode(json);
    this.connection.send(data);
    window.console.debug("dataOut: ${data}");
  }

  void receiveMessage(String message) {
    if (!this.isListening) {
      window.console.debug("Data received but client isn't listening yet");
      return;
    }

    var data = JSON.decode(message);
    window.console.debug("dataIn: ${message}");

    if (data[0] is List) {
      // Multiple actions received
      this.receiveActionBatch(data);
    } else {
      // Only one action received
      this.receiveAction(data);
    }
  }

  void receiveAction(data) {
    this.trigger(data[0], [data]);
  }

  void receiveActionBatch(actions) {
    actions.forEach((action) {
      this.receiveAction(action);
    });
  }

  void disconnected(String message) {
    if (Game.player) {
      Game.player.die();
    }

    Game.disconnected(message);
  }

  // TODO: uncomment
  /*void sendInventory(Inventory inventory) {*/
    /*this.sendMessage([Message.INVENTORY,*/
      /*inventory.serialize()*/
    /*]);*/
  /*}*/

  void sendInventoryItem(InventoryItem item) {
    this.sendMessage([Message.INVENTORYITEM,
        item.serialize()
    ]);
  }

  void sendInventorySwap(first, second) {
    this.sendMessage([Message.INVENTORYSWAP,
      first,
      second
    ]);
  }

  void sendUseItem(Item item, [Entity target = null]) {
    var message = [Message.USEITEM,
      item.id
    ];
    if (target != null) {
      message.add(target.id);
    }

    this.sendMessage(message);
  }

  void sendUseSpell(
    Spell spell, 
    Entity target, 
    Orientation orientation, 
    int trackingId
  ) {
    var message = [Message.USESPELL,
      spell.kind
    ];

    var targetId = null;
    if (target != null) {
      targetId = target.id;
    }
    message.add(targetId);
    message.add(orientation);
    message.add(trackingId);

    this.sendMessage(message);
  }

  // TODO: uncomment
  /*void sendSkillbar(Skillbar skillbar) {*/
    /*this.sendMessage([Message.SKILLBAR,*/
      /*skillbar.serialize()*/
    /*]);*/
  /*}*/

  void sendThrowItem(Item item, [Entity target = null]) {
    List message = [Message.THROWITEM,
      item.id
    ];
    if (target != null) {
      message.add(target.id);
    }

    this.sendMessage(message);
  }

  void sendHello(String playerName, bool isResurrection) {
    this.sendMessage([Message.HELLO,
      playerName
    ]);
  }

  void sendResurrect() {
    this.sendMessage([Message.RESURRECT]);
  }

  void sendMove(int x, int y) {
    this.sendMessage([Message.MOVE,
      x,
      y
    ]);
  }

  void sendLootMove(Item item, int x, int y) {
    this.sendMessage([Message.LOOTMOVE,
      x,
      y,
      item.id
    ]);
  }

  void sendAggro(Mob mob) {
    this.sendMessage([Message.AGGRO,
      mob.id
    ]);
  }

  void sendAttack(Mob mob) {
    this.sendMessage([Message.ATTACK,
      mob.id
    ]);
  }

  void sendHit(Mob mob) {
    this.sendMessage([Message.HIT,
      mob.id
    ]);
  }

  void sendHurt(Mob mob) {
    this.sendMessage([Message.HURT,
      mob.id
    ]);
  }

  void sendChat(String text, String channel) {
    if (!channel) {
      channel = this.chat.channel;
    }
    this.sendMessage([Message.CHAT,
      text,
      channel
    ]);
  }

  void sendPartyAccept(int inviterId) {
    this.sendMessage([Message.PARTY_ACCEPT,
      inviterId
    ]);
  }

  void sendPartyLeaderChange(int playerID) {
    this.sendMessage([Message.PARTY_LEADER_CHANGE,
      playerID
    ]);
  }

  void sendPartyLeave() {
    this.sendMessage([Message.PARTY_LEAVE]);
  }

  void sendPartyInvite(int playerId) {
    this.sendMessage([Message.PARTY_INVITE,
      Game.player.id,
      playerId
    ]);
  }

  void sendPartyKick(int playerId) {
    this.sendMessage([Message.PARTY_KICK,
      playerId
    ]);
  }

  void sendGuildCreate(String name) {
    this.sendMessage([Message.GUILD_CREATE,
      name
    ]);
  }

  void sendGuildAccept(String name) {
    this.sendMessage([Message.GUILD_ACCEPT,
      name
    ]);
  }

  void sendGuildLeaderChange(String name) {
    this.sendMessage([Message.GUILD_LEADER_CHANGE,
      name
    ]);
  }

  void sendGuildQuit() {
    this.sendMessage([Message.GUILD_QUIT]);
  }

  void sendGuildInvite(String name) {
    this.sendMessage([Message.GUILD_INVITE,
      name
    ]);
  }

  void sendGuildKick(String name) {
    this.sendMessage([Message.GUILD_KICK,
      name
    ]);
  }

  void sendGuildOnline() {
    this.sendMessage([Message.GUILD_ONLINE]);
  }

  void sendGuildMembers() {
    this.sendMessage([Message.GUILD_MEMBERS]);
  }

  void sendLoot(Item item) {
    this.sendMessage([Message.LOOT,
      item.id
    ]);
  }

  void sendTeleport(int x, int y) {
    this.sendMessage([Message.TELEPORT,
      x,
      y
    ]);
  }

  void sendWho(List<int> ids) {
    List data = [Message.WHO];
    data.addAll(ids);
    this.sendMessage(data);
  }

  void sendZone() {
    this.sendMessage([Message.ZONE]);
  }

  void sendOpen(Chest chest) {
    this.sendMessage([Message.OPEN,
      chest.id
    ]);
  }

  void sendCheck(int id) {
    this.sendMessage([Message.CHECK,
      id
    ]);
  }

  void handlePlayerEnter(playerData) {
    Player player = Game.getPlayerByID(playerData.id);
    if (player != null) {
      // already exists - skip it
      return;
    }

    player = EntityFactory.createEntity(playerData.kind, playerData.id, playerData.name);
    player.loadFromObject(playerData.data);
    Game.addPlayer(player);
  }
}
