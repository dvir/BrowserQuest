var cls = require("./lib/class"),
  _ = require("underscore"),
  Messages = require("./message"),
  Utils = require("./utils"),
  Properties = require("./properties"),
  Formulas = require("./formulas"),
  check = require("./format").check,
  DB = require("./db"),
  Inventory = require("./inventory"),
  Skillbar = require("./skillbar"),
  Spellbook = require("./spellbook"),
  Party = require("./party"),
  Types = require("../../shared/js/gametypes");

module.exports = Player = Character.extend({
  init: function (connection, worldServer) {
    this.server = worldServer;
    this.connection = connection;

    this._super(this.connection.id, "player", Types.Entities.PLAYER, 0, 0, "");

    Utils.Mixin(this.data, {
      xp: 0
    });

    this.inventory = null;

    this.hasEnteredGame = false;
    this.isAutoEquip = true;
    this.haters = {};
    this.hatelist = [];
    this.lastCheckpoint = null;
    this.formatChecker = new FormatChecker();
    this.disconnectTimeout = null;
    this._partyInvites = {};
    this._guildInvites = {};

    this.connection.on("Message", function (message) {
      var action = parseInt(message[0]);

      log.debug("Received (" + this.connection.id + "): " + message);
      if (!check(message)) {
        this.connection.close("Invalid " + Types.getMessageTypeAsString(action) + " message format: " + message);
        return;
      }

      if (!this.hasEnteredGame && action !== Types.Messages.HELLO) { // HELLO must be the first message
        this.connection.close("Invalid handshake message: " + message);
        return;
      }
      if (this.hasEnteredGame && !this.isDead && action === Types.Messages.HELLO) { // HELLO can be sent only once
        this.connection.close("Cannot initiate handshake twice: " + message);
        return;
      }

      this.resetTimeout();

      if (action === Types.Messages.RESURRECT) {
        this.hp = this.maxHP / 2;
        this.enter(true);
      } else if (action === Types.Messages.HELLO) {
        var name = Utils.sanitize(message[1]);

        // If name was cleared by the sanitizer, give a default name.
        // Always ensure that the name is not longer than a maximum length.
        // (also enforced by the maxlength attribute of the name input element).
        this.name = (name === "") ? "lorem ipsum" : name.substr(0, 15);

        this.kind = Types.Entities.PLAYER;
        this.orientation = Utils.randomOrientation();

        // find previous player with this id
        Players
        .findOne({name: this.name})
        .populate('guild')
        .exec(function (err, dbPlayer) {
          if (err) {
            return;
          }

          if (dbPlayer) {
            log.debug("Found previous player record '" + dbPlayer.name + "'");
          } else {
            log.debug("Creating new player record '" + this.name + "'");
            var dbPlayer = new Players({
              name: this.name,
              xp: this.xp,
              level: this.level,
              hp: this.hp,
              armor: 21,
              weapon: 60,
              x: this.x,
              y: this.y
            });
          }

          dbPlayer.online = true;
          dbPlayer.save(function(err) {
            if (err) { log.error("Failed saving dbPlayer on enter"); return; }
            this.setDBEntity(dbPlayer, this.enter.bind(this));
          }.bind(this));
        }.bind(this));
      } else if (action === Types.Messages.WHO) {
        message.shift();
        this.server.pushSpawnsToPlayer(this, message);
      } else if (action === Types.Messages.ZONE) {
        this.trigger("Zone");
      } else if (action === Types.Messages.CHAT) {
        var msg = Utils.sanitize(message[1]);
        var channel = message[2];

        // Sanitized messages may become empty. No need to broadcast empty chat messages.
        if (msg && msg !== "") {
          msg = msg.substr(0, 60); // Enforce maxlength of chat input
          if (channel == "global") {
            this.server.pushBroadcast(new Messages.Chat(this, msg, channel));
          } else if (channel == "yell") {
            this.broadcast(new Messages.Chat(this, msg, channel), false);
          } else if (channel == "party") {
            if (this.party) {
              this.party.broadcast(new Messages.Chat(this, msg, channel).serialize());
            }
          } else if (channel == "guild") {
            if (this.guild) {
              this.guild.broadcast(this.server, new Messages.Chat(this, msg, channel).serialize());
            }
          } else if (channel == "say") {
            this.broadcastToZone(new Messages.Chat(this, msg, channel), false);
          }
        }
      } else if (action === Types.Messages.MOVE) {
        var x = message[1],
          y = message[2];

        if (this.server.isValidPosition(x, y)) {
          this.setPosition(x, y);
          this.clearTarget();

          this.broadcast(new Messages.Move(this), true);
          this.trigger("Move", this.x, this.y);
        }
      } else if (action === Types.Messages.LOOTMOVE) {
        this.setPosition(message[1], message[2]);

        var item = this.server.getEntityById(message[3]);
        if (item) {
          this.clearTarget();

          this.broadcast(new Messages.LootMove(this, item), true);
          this.trigger("LootMove", this.x, this.y);
        }
      } else if (action === Types.Messages.AGGRO) {
        this.server.handleMobHate(message[1], this.id, 5);
      } else if (action === Types.Messages.ATTACK) {
        var mob = this.server.getEntityById(message[1]);

        if (mob) {
          this.setTarget(mob);
          this.server.broadcastAttacker(this);
        }
      } else if (action === Types.Messages.HIT) {
        var target = this.server.getEntityById(message[1]);
        if (target) {
          var dmg = Formulas.dmg(this.weaponLevel, target.armorLevel);

          if (dmg > 0) {
            target.receiveDamage(dmg, this.id);

            if (target instanceof Mob) {
              this.server.handleMobHate(target.id, this.id, dmg);
            }

            this.server.handleHurtEntity(target, this, dmg);
          }
        }
      } else if (action === Types.Messages.HURT) {
        var mob = this.server.getEntityById(message[1]);
        if (mob && this.hp > 0) {
          var damage = Formulas.dmg(mob.weaponLevel, this.armorLevel);
          this.hp -= damage;
          this.server.handleHurtEntity(this, mob, damage);

          if (this.hp <= 0) {
            this.isDead = true;
            if (this.firepotionTimeout) {
              clearTimeout(this.firepotionTimeout);
            }
          }
        }
      } else if (action === Types.Messages.LOOT) {
        var item = this.server.getEntityById(message[1]);
        if (item) {
          if (Types.isItem(item.kind)) {
            this.lootedItem(item);
          }
        }
      } else if (action === Types.Messages.TELEPORT) {
        var x = message[1],
          y = message[2];
        if (this.server.isValidPosition(x, y)) {
          this.setPosition(x, y);
          this.clearTarget();

          this.broadcast(new Messages.Teleport(this));

          this.server.handlePlayerVanish(this);
          this.server.pushRelevantEntityListTo(this);
        }
      } else if (action === Types.Messages.OPEN) {
        var chest = this.server.getEntityById(message[1]);
        if (chest && chest instanceof Chest) {
          this.server.handleOpenedChest(chest, this);
        }
      } else if (action === Types.Messages.CHECK) {
        var checkpoint = this.server.map.getCheckpoint(message[1]);
        if (checkpoint) {
          this.lastCheckpoint = checkpoint;
        }
      } else if (action === Types.Messages.INVENTORY) {

      } else if (action === Types.Messages.INVENTORYITEM) {
        var data = message[1];
        var inventoryItemId = data.id;
        delete data.id;

        //                Items.update({_id: inventoryItemId}, {$set: data});
        data._id = inventoryItemId;
        Items.save(data, function () {
          this.inventory.loadFromDB();
        }.bind(this));
      } else if (action === Types.Messages.INVENTORYSWAP) {
        var first = message[1],
          second = message[2];
        this.inventory.swap(first, second);
      } else if (action === Types.Messages.USEITEM) {
        var id = message[1];
        var item = this.inventory.find(id);
        if (item) {
          item.use();
        }
      } else if (action === Types.Messages.USESPELL) {
        var spellId = message[1],
          targetId = message[2],
          orientation = message[3],
          trackingId = message[4];

        var target = this.server.getEntityById(targetId, true);
        this.spellbook.use(spellId, target, orientation, trackingId);
      } else if (action === Types.Messages.SKILLBAR) {
        var slots = message[1];

        if (slots) {
          data = {
            slots: slots,
            playerId: this.getId(),
            size: 12
          };

          Skillbars.findOneAndUpdate({
            playerId: this.getId()
          }, data, {
            upsert: true
          }, DB.defaultCallback);
        }
      } else if (action === Types.Messages.THROWITEM) {
        var id = message[1];
        var targetId = null;
        if (message[2]) {
          targetId = message[2];
        }
        var item = this.inventory.find(id);
        var target = this;
        if (targetId) {
          this.server.getEntityById(targetId);
        }

        if (item) {
          this.throwItem(item, target);
        }
      } else if (action === Types.Messages.PARTY_INVITE) {
        var inviter = this.server.getPlayerByID(message[1]);
        var invitee = this.server.getPlayerByID(message[2]);

        inviter.partyInvite(invitee);
      } else if (action === Types.Messages.PARTY_KICK) {
        var player = this.server.getPlayerByID(message[1]);

        this.kick(player);
      } else if (action === Types.Messages.PARTY_ACCEPT) {
        var inviter = this.server.getPlayerByID(message[1]);

        if (!inviter.hasPartyInvited(this)) {
          // no invitation pending for this player
          return;
        }

        if (inviter.party) {
          if (!inviter.party.isLeader(inviter)) {
            // the inviter is not the party leader and therefore 
            // cannot issue any invitation
            return;
          }

          inviter.party.join(this);
        } else {
          new Party(inviter, this);
        }

        inviter.removePartyInvite(this);
      } else if (action === Types.Messages.PARTY_LEAVE) {
        if (this.party) {
          this.party.leave(this);
        }
      } else if (action === Types.Messages.PARTY_LEADER_CHANGE) {
        var newLeader = this.server.getPlayerByID(message[1]);

        if (newLeader != this && this.party && this.party.isLeader(this) && this.party.isMember(newLeader)) {
          this.party.leader = newLeader;
        }
      } else if (action === Types.Messages.GUILD_CREATE) {
        var name = message[1];

        if (this.guild) {
          // already have a guild!
          this.sendCommandError("You are already in a guild.");
          return;
        }

        if (name.length > Guilds.nameMaxLength()) {
          this.sendCommandError("The maximum length for a guild name is " + Guilds.nameMaxLength() + " characters.");
          return;
        }

        Guilds.isAvailableName(name, function (isAvailable) {
          if (!isAvailable) {
            // guild name is taken. let the player know
            this.sendCommandError("Guild name '"+name+"' is taken.");
            return;
          }

          Guilds.create(name, this, function(guild) {
            this.guild = guild;
            this.sendCommandNotice("Created guild '"+name+"'.");                   
          }.bind(this));
        }.bind(this));
      } else if (action === Types.Messages.GUILD_QUIT) {
        if (!this.guild) {
          // cannot gquit when not in a guild
          this.sendCommandError("You are not in a guild.");
          return;
        }

        this.guild.removeMember(this, function(guild) { 
          this.guild = null; 
          this.sendCommandNotice("You have left the guild.");                   
          guild.broadcast(this.server, new Messages.GuildLeft(this, guild).serialize());
        }.bind(this));
      } else if (action === Types.Messages.GUILD_INVITE) {
        if (!this.guild) {
          // cannot ginvite when not in a guild
          this.sendCommandError("You are not in a guild.");
          return;
        }

        if (!this.guild.isLeader(this)) {
          // the inviter is not the guild leader and therefore 
          // cannot issue any invitation
          this.sendCommandError("You are not the guild leader.");
          return;
        }

        var name = message[1];
        var player = this.server.getPlayerByName(name);

        if (!player) {
          Players.count({name: name}, function (err, count) {
            if (err) {
              log.debug("error on count of players - player.js::guild_invite: " + err);
              return;
            }

            if (count > 0) {
              this.sendCommandError("Cannot invite an offline player to the guild.");
              return;
            }

            this.sendCommandError("Unknown player '"+name+"'.");
          }.bind(this));
          return;
        }

        if (player.guild) {
          this.sendCommandError(name+" is already in a guild.");
          return;
        }

        this.guildInvite(player);
        this.sendCommandNotice(name+" has been invited to join '"+this.guild.name+"'.");
      } else if (action === Types.Messages.GUILD_KICK) {
        var name = message[1];
        var player = this.server.getPlayerByName(name);

        if (!player) {
          this.sendCommandError("Unknown player '"+name+"'");
          return;
        }
        if (!this.guild) {
          // cannot gkick when not in a guild
          this.sendCommandError("You are not in a guild.");
          return;
        }
        if (!this.guild.isLeader(this)) {
          this.sendCommandError("You are not the guild leader.");
          return;
        }
        if (player == this) {
          this.sendCommandError("You cannot kick yourself from a guild.");
          return;
        }
        if (!this.guild.isMember(player)) {
          this.sendCommandError(name+" is not a member of your guild.");
          return;
        }

        this.guild.kick(this, player, function (guild) {
          player.guild = null;
          guild.broadcast(this.server, new Messages.GuildKick(this, player).serialize());
          player.send(new Messages.GuildKick(this, player).serialize());
        }.bind(this));
      } else if (action === Types.Messages.GUILD_LEADER_CHANGE) {
        var name = message[1];
        var player = this.server.getPlayerByName(name);

        if (!player) {
          this.sendCommandError("Unknown player '"+name+"'");
          return;
        }
        if (!this.guild) {
          // cannot gleader when not in a guild
          this.sendCommandError("You are not in a guild.");
          return;
        }
        if (!this.guild.isLeader(this)) {
          this.sendCommandError("You are not the guild leader.");
          return;
        }
        if (player == this) {
          this.sendCommandError("You are already the guild leader.");
          return;
        }
        if (!this.guild.isMember(player)) {
          this.sendCommandError(name+" is not a member of your guild.");
          return;
        }

        this.guild.setLeader(player);
      } else if (action === Types.Messages.GUILD_ACCEPT) {
        var name = message[1];
        var inviter = this.server.getPlayerByName(name);

        if (!inviter.hasGuildInvited(this)) {
          // no invitation pending for this player
          return;
        }

        if (inviter.guild) {
          if (!inviter.guild.isLeader(inviter)) {
            // the inviter is not the guild leader and therefore 
            // cannot issue any invitation
            return;
          }

          inviter.guild.addMember(this, function(_, guild) {
            this.guild = guild;
            guild.broadcast(this.server, new Messages.GuildJoined(this, guild).serialize());
          }.bind(this));
        }

        inviter.removePartyInvite(this);
      } else if (action === Types.Messages.GUILD_MEMBERS) {
        if (!this.guild) {
          this.sendCommandError("You are not in a guild.");
          return;
        }

        this.guild.getMembersPlayers(function(members) {
          this.send(new Messages.GuildMembers(members).serialize());
        }.bind(this));
      } else {
        log.error("Unknown message received:");
        log.error(message);
      }
    }.bind(this));

    this.connection.on("Close", function () {
      if (this.firepotionTimeout) {
        clearTimeout(this.firepotionTimeout);
      }
      clearTimeout(this.disconnectTimeout);
      this.dbEntity.online = false;
      this.dbEntity.save(function(err) {
        if (err) { log.error("Failed saving dbPlayer on exit"); return; }
      }.bind(this));
      this.trigger("exit");
    }.bind(this));

    this.connection.sendUTF8("go"); // Notify client that the HELLO/WELCOME handshake can start
  },

  kick: function (player) {
    if (this.party && this.party.isLeader(this) && this.party.isMember(player)) {
      this.party.kick(player);
    }
  },

  partyInvite: function (invitee) {
    if (!this.party || (!this.party.isFull() && this.party.isLeader(this))) {
      // automatically remove the invite after 60 seconds
      var inviteTimeout = setTimeout(function () {
        this.removePartyInvite(invitee.id);
      }.bind(this), 60);
      this._partyInvites[invitee.id] = {
        invitee: invitee,
        timeout: inviteTimeout
      };
      invitee.send(new Messages.PartyInvite(this, invitee).serialize());
    }
  },

  removePartyInvite: function (player) {
    var invitation = this._partyInvites[player.id];
    if (invitation) {
      clearTimeout(invitation.timeout);
      delete this._partyInvites[player.id];
    }
  },

  resetPartyInvites: function () {
    for (var x in this._partyInvites) {
      clearTimeout(this._partyInvites[x].timeout);
      delete this._partyInvites[x];
    }
  },

  hasPartyInvited: function (player) {
    return (player.id in this._partyInvites);
  },

  guildInvite: function (invitee) {
    if (!this.guild || (!this.guild.isFull() && this.guild.isLeader(this))) {
      // automatically remove the invite after 60 seconds
      var inviteTimeout = setTimeout(function () {
        this.removeGuildInvite(invitee.id);
      }.bind(this), 60);
      this._guildInvites[invitee.id] = {
        invitee: invitee,
        timeout: inviteTimeout
      };
      invitee.send(new Messages.GuildInvite(this, this.guild).serialize());
    }
  },

  removeGuildInvite: function (player) {
    var invitation = this._guildInvites[player.id];
    if (invitation) {
      clearTimeout(invitation.timeout);
      delete this._guildInvites[player.id];
    }
  },

  resetGuildInvites: function () {
    for (var x in this._guildInvites) {
      clearTimeout(this._guildInvites[x].timeout);
      delete this._guildInvites[x];
    }
  },

  hasGuildInvited: function (player) {
    return (player.id in this._guildInvites);
  },

  destroy: function () {
    this.forEachAttacker(function (mob) {
      mob.clearTarget();
    }.bind(this));
    this.attackers = {};

    this.forEachHater(function (mob) {
      mob.forgetPlayer(this.id);
    }.bind(this));
    this.haters = {};
  },

  getState: function () {
    var basestate = this._super(),
      state = [this.name, this.armor, this.weapon];

    return basestate.concat(state);
  },

  getBasicState: function () {
    return {
      id: this.id,
      kind: this.kind,
      name: this.name,
      data: {
        hp: this.hp,
        maxHP: this.maxHP,
        level: this.level,
        guild: this.guild ? {name: this.guild.name} : null
      }
    };
  },

  send: function (message) {
    log.debug("Sent (" + this.connection.id + "): " + message);
    this.connection.send(message);
  },

  sendCommandNotice: function (notice) {
    this.send(new Messages.CommandNotice(notice).serialize());
  },

  sendCommandError: function (error) {
    this.send(new Messages.CommandError(error).serialize());
  },

  sendError: function (error) {
    this.send(new Messages.Error(error).serialize());
  },

  broadcast: function (message, ignoreSelf) {
    this.trigger("Broadcast", message, ignoreSelf === undefined ? false : ignoreSelf);
  },

  broadcastToZone: function (message, ignoreSelf) {
    this.trigger("BroadcastToZone", message, ignoreSelf === undefined ? false : ignoreSelf);
  },

  equip: function (item) {
    return new Messages.EquipItem(this, item);
  },

  drop: function (item) {
    return new Messages.Drop(this, item);
  },

  addHater: function (mob) {
    if (mob) {
      if (!(mob.id in this.haters)) {
        this.haters[mob.id] = mob;
      }
    }
  },

  removeHater: function (mob) {
    if (mob && mob.id in this.haters) {
      delete this.haters[mob.id];
    }
  },

  forEachHater: function (callback) {
    _.each(this.haters, function (mob) {
      callback(mob);
    });
  },

  sync: function () {
    this.send(new Messages.Data(this.getData()).serialize());
    this.broadcast(new Messages.PlayerUpdate(this));
  },

  syncInventory: function () {
    this.send(new Messages.Inventory(this.inventory).serialize());
  },

  throwItem: function (item, target) {
    item.remove();
    var thrownItem = this.server.addItem(this.server.createItem(item.kind, target.x, target.y));
    this.server.pushToAdjacentGroups(this.group, this.drop(thrownItem));
    this.server.handleItemDespawn(thrownItem);
  },

  lootedItem: function (item) {
    var newItem = this.inventory.add(item);
    if (newItem) {
      log.debug(this.name + " looted " + Types.getKindAsString(item.kind));
      this.server.pushToPlayer(this, this.loot(newItem));
      this.broadcast(item.despawn());
      this.server.removeEntity(item);

      if (item.useOnPickup) {
        newItem.use();
      }
    } else {
      // no room for this item in the inventory!
      // do not pick it up.
      return;
    }
  },

  killed: function (victim) {
    this.send(new Messages.Kill(victim).serialize());

    var xp = Formulas.xp(this, victim);
    this.xp += xp;
  },

  defeated: function (victim) {
    this.server.pushBroadcast(new Messages.Defeated(this, victim));
  },

  loot: function (item) {
    return new Messages.Loot(item);
  },

  getId: function () {
    return this.dbEntity._id;
  },

  set xp(xp) {
    this.isDirty = true;

    var diff = xp - this.xp;

    if (xp >= this.maxXP) {
      // level up!
      this.data.xp = xp - this.maxXP;
      this.levelUp();
    } else {
      this.data.xp = xp;
    }

    this.send(new Messages.XP(this.xp, this.maxXP, diff).serialize());
    this.save();
  },

  get xp() {
    return this.data.xp;
  },

  get maxXP() {
    return this.level * 100;
  },

  set guild(guild) {
    this.data.guild = guild;
    this.isDirty = true;
    this.save();
    this.sync();
  },
  get guild() {
    return this.data.guild;
  },

  levelUp: function () {
    this.level++;
    this.hp = this.maxHP;

    this.sync();
  },

  updatePosition: function (isResurrection) {
    var pos = this.requestPosition(isResurrection);
    this.setPosition(pos.x, pos.y);
  },

  requestPosition: function (isResurrection) {
    if (isResurrection && this.lastCheckpoint) {
      return this.lastCheckpoint.getRandomPosition();
    }

    if (this.x == 0 && this.y == 0) {
      return this.server.map.getRandomStartingPosition();
    } else {
      return {
        x: this.x,
        y: this.y
      };
    }
  },

  enter: function (isResurrection) {
    this.updatePosition(isResurrection);
    this.send([Types.Messages.WELCOME, this.getData()]);
    this.hasEnteredGame = true;
    this.isDead = false;

    this.server.addPlayer(this, function () {
      this.server.entered(this);
    }.bind(this));
  },

  resetTimeout: function () {
    clearTimeout(this.disconnectTimeout);
    this.disconnectTimeout = setTimeout(this.timeout.bind(this), 1000 * 60 * 15); // 15 min.
  },

  timeout: function () {
    this.connection.sendUTF8("timeout");
    this.connection.close("Player was idle for too long");
  },

  setDBEntity: function (dbEntity, callback) {
    this.dbEntity = dbEntity;

    this.loadFromDB(callback);
  },

  loadFromDB: function (callback) {
    if (!this.dbEntity) return;

    this._super();

    Utils.Mixin(this.data, {
      name: this.dbEntity.name,
      level: this.dbEntity.level,
      hp: this.dbEntity.hp,
      xp: this.dbEntity.xp,
      weapon: this.dbEntity.weapon,
      armor: this.dbEntity.armor,
      x: this.dbEntity.x,
      y: this.dbEntity.y,
      guild: this.dbEntity.guild
    });

    this.spellbook = new Spellbook(this);
    this.inventory = new Inventory(this, function () {
      this.skillbar = new Skillbar(this, callback);
    }.bind(this));
  },

  save: function () {
    if (!this.dbEntity || !this.isDirty) return;

    //        Utils.Mixin(this.dbEntity, this.data);
    this.dbEntity.xp = this.data.xp;
    this.dbEntity.hp = this.data.hp;
    this.dbEntity.level = this.data.level;
    this.dbEntity.name = this.data.name;
    this.dbEntity.weapon = this.data.weapon;
    this.dbEntity.armor = this.data.armor;
    this.dbEntity.x = this.data.x;
    this.dbEntity.y = this.data.y;
    this.dbEntity.guild = (this.data.guild ? this.data.guild._id : null);

    this._super();
    this.inventory.save();
  },

  getData: function () {
    var dataObject = this.data;
    Utils.Mixin(dataObject, {
      maxXP: this.maxXP,
      maxHP: this.maxHP,
      id: this.id,
      inventory: this.inventory.serialize(),
      skillbar: this.skillbar.serialize()
    });

    return dataObject;
  }
});
