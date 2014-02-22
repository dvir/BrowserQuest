var cls = require("./lib/class"),
  _ = require("underscore"),
  Log = require('log'),
  Entity = require('./entity'),
  Character = require('./character'),
  Mob = require('./mob'),
  Map = require('./map'),
  Npc = require('./npc'),
  Player = require('./player'),
  Item = require('./item'),
  MobArea = require('./mobarea'),
  ChestArea = require('./chestarea'),
  Chest = require('./chest'),
  Messages = require('./message'),
  Properties = require("./properties"),
  Utils = require("./utils"),
  DB = require("./db"),
  Formulas = require("./formulas"),
  Types = require("../../shared/js/gametypes");

// ======= GAME SERVER ========

module.exports = World = cls.Class.extend({
  init: function (id, maxPlayers, websocketServer, map_filepath) {
    this.id = id;
    this.maxPlayers = maxPlayers;
    this.server = websocketServer;
    this.ups = 50;

    this.map = null;

    this.entities = {};
    this.players = {};
    this.playersByDBID = {};
    this.playersByName = {};
    this.mobs = {};
    this.attackers = {};
    this.items = {};
    this.equipping = {};
    this.hurt = {};
    this.npcs = {};
    this.mobAreas = [];
    this.chestAreas = [];
    this.groups = {};

    this.outgoingQueues = {};

    this.itemCount = 0;
    this.playerCount = 0;

    this.zoneGroupsReady = false;

    DB.connection.once('open', function callback() {
      console.log("DB is ready");
      var dbPlayersCount = Players.count({}, function (err, count) {
        if (err) {
          return;
        }

        console.log("There are %d players in the database.", count);
      });
      this.run(map_filepath);
    }.bind(this));
  },

  run: function (mapFilePath) {
    this.map = new Map(mapFilePath);

    this.map.ready(function () {
      this.initZoneGroups();

      this.map.generateCollisionGrid();

      // Populate all mob "roaming" areas
      _.each(this.map.mobAreas, function (a) {
        var area = new MobArea(a.id, a.nb, a.type, a.x, a.y, a.width, a.height, this);
        area.spawnMobs();
        area.on("Empty", this.handleEmptyMobArea.bind(this, area));

        this.mobAreas.push(area);
      }.bind(this));

      // Create all chest areas
      _.each(this.map.chestAreas, function (a) {
        var area = new ChestArea(a.id, a.x, a.y, a.w, a.h, a.tx, a.ty, a.i, this);
        this.chestAreas.push(area);
        area.on("Empty", this.handleEmptyChestArea.bind(this, area));
      }.bind(this));

      // Spawn static chests
      _.each(this.map.staticChests, function (chest) {
        var c = this.createChest(chest.x, chest.y, chest.i);
        this.addStaticItem(c);
      }.bind(this));

      // Spawn static entities
      this.spawnStaticEntities();

      // Set maximum number of entities contained in each chest area
      _.each(this.chestAreas, function (area) {
        area.setNumberOfEntities(area.entities.length);
      }.bind(this));
    }.bind(this));

    var regenCount = this.ups * 2;
    var updateCount = 0;
    setInterval(function () {
      this.processGroups();
      this.processQueues();

      if (updateCount < regenCount) {
        updateCount += 1;
      } else {
        this.regenTick();
        updateCount = 0;
      }
    }.bind(this), 1000 / this.ups);

    log.info("" + this.id + " created (capacity: " + this.maxPlayers + " players).");
  },

  setUpdatesPerSecond: function (ups) {
    this.ups = ups;
  },

  connected: function (player) {
    log.info(player.name + " has connected " + this.id);
  },

  entered: function (player) {
    log.info(player.name + " has joined " + this.id);

    if (player.guild) {
      player.guild.broadcast(this, new Messages.GuildOnline(player).serialize());
    }

    this.pushToPlayer(player, new Messages.Players(this.players));
    this.pushBroadcast(new Messages.PlayerEnter(player), player);

    this.incrementPlayerCount();
    this.pushRelevantEntityListTo(player);

    var move_callback = function (x, y) {
      log.debug(player.name + "(" + player.connection.id + ") is moving to (" + x + ", " + y + ").");

      player.forEachAttacker(function (mob) {
        var target = this.getEntityById(mob.target);
        if (target) {
          var pos = this.findPositionNextTo(mob, target);
          if (mob.distanceToSpawningPoint(pos.x, pos.y) > 50) {
            mob.clearTarget();
            mob.forgetEveryone();
            player.removeAttacker(mob);
          } else {
            this.moveEntity(mob, pos.x, pos.y);
          }
        }
      }.bind(this));
    }.bind(this);

    player.on(["Move", "LootMove"], move_callback);

    player.on("Zone", function () {
      var hasChangedGroups = this.handleEntityGroupMembership(player);

      if (hasChangedGroups) {
        this.pushToPreviousGroups(player, new Messages.Destroy(player));
        this.pushRelevantEntityListTo(player);
      }
    }.bind(this));

    player.on("Broadcast", function (message, ignoreSelf) {
      var ignore = {};
      if (ignoreSelf) {
        ignore[player.id] = true;
      }

      if (player.party) {
        var targets = this.pushToPlayerParty(player, message, ignore);
        _.extend(ignore, targets);
      }

      this.pushToAdjacentGroups(player.group, message, ignore);
    }.bind(this));

    player.on("BroadcastToZone", function (message, ignoreSelf) {
      var ignore = {};
      if (ignoreSelf) {
        ignore[player.id] = true;
      }

      if (player.party) {
        var targets = this.pushToPlayerParty(player, message, ignore);
        _.extend(ignore, targets);
      }

      this.pushToGroup(player.group, message, ignore);
    }.bind(this));

    player.on("exit", function () {
      if (player.party) {
        player.party.leave(player);
      }

      if (player.guild) {
        player.guild.broadcast(this, new Messages.GuildOffline(player).serialize());
      }

      this.pushBroadcast(new Messages.PlayerExit(player), player);

      this.removePlayer(player);
      this.decrementPlayerCount();

      this.trigger("PlayerRemoved");

      log.info(player.name + " has left the game.");
    }.bind(this));

    this.trigger("PlayerAdded");
  },

  regenTick: function () {
    this.forEachCharacter(function (character) {
      if (!character.hasFullHealth()) {
        character.regenHealthBy(Formulas.regenHP(character));

        if (character.type === 'player') {
          character.broadcast(character.regen(), false);
        }
      }
    });
  },

  pushRelevantEntityListTo: function (player) {
    var entities;
    if (player && (player.group in this.groups)) {
      entities = _.keys(this.groups[player.group].entities);
      entities = _.reject(entities, function (id) {
        return id == player.id;
      });
      entities = _.map(entities, function (id) {
        return parseInt(id);
      });
      if (entities) {
        this.pushToPlayer(player, new Messages.List(entities));
      }
    }
  },

  pushSpawnsToPlayer: function (player, ids) {
    _.each(ids, function (id) {
      var entity = this.getEntityById(id);
      if (entity) {
        this.pushToPlayer(player, new Messages.Spawn(entity));
      }
    }.bind(this));

    log.debug("Pushed " + _.size(ids) + " new spawns to " + player.id);
  },

  pushToPlayer: function (player, message) {
    if (!player) {
      log.error("pushToPlayer: player was undefined");
      return;
    }

    if (player && player.id in this.outgoingQueues) {
      this.outgoingQueues[player.id].push(message.serialize());
    }
  },

  pushToPlayerParty: function (player, message, ignoredPlayersIDs) {
    return this.pushToParty(player.party, message, ignoredPlayersIDs);
  },

  pushToParty: function (party, message, ignoredPlayersIDs) {
    var targets = {};

    _.each(party.getMembers(), function (player) {
      if (player.id in ignoredPlayersIDs) {
        return;
      }

      targets[player.id] = true;
      this.pushToPlayer(player, message);
    }.bind(this));

    return targets;
  },

  pushToGroup: function (groupId, message, ignoredPlayersIDs) {
    var group = this.groups[groupId];

    // if a non-object player given, assume it's a single id of a player
    // to exclude from this message and construct a proper list from it.
    if (!(ignoredPlayersIDs instanceof Object)) {
      var playersIDs = {};
      if (ignoredPlayersIDs) {
        playersIDs[ignoredPlayersIDs] = true;
      }

      ignoredPlayersIDs = playersIDs;
    }

    if (group) {
      _.each(group.players, function (playerId) {
        if (playerId in ignoredPlayersIDs) {
          return;
        }

        this.pushToPlayer(this.getEntityById(playerId), message);
      }.bind(this));
    } else {
      log.error("groupId: " + groupId + " is not a valid group");
    }
  },

  pushToAdjacentGroups: function (groupId, message, ignoredPlayersIDs) {
    this.map.forEachAdjacentGroup(groupId, function (id) {
      this.pushToGroup(id, message, ignoredPlayersIDs);
    }.bind(this));
  },

  pushToPreviousGroups: function (player, message) {
    // Push this message to all groups which are not going to be updated anymore,
    // since the player left them.
    _.each(player.recentlyLeftGroups, function (id)  {
      this.pushToGroup(id, message);
    }.bind(this));
    player.recentlyLeftGroups = [];
  },

  pushBroadcast: function (message, ignoredPlayersIDs) {
    if (!(ignoredPlayersIDs instanceof Object)) {
      var playersIDs = {};
      if (ignoredPlayersIDs) {
        playersIDs[ignoredPlayersIDs] = true;
      }

      ignoredPlayersIDs = playersIDs;
    }

    for (var id in this.outgoingQueues) {
      if (id in ignoredPlayersIDs) {
        continue;
      }

      this.outgoingQueues[id].push(message.serialize());
    }
  },

  processQueues: function ()  {
    for (var id in this.outgoingQueues) {
      if (this.outgoingQueues[id].length == 0) {
        continue;
      }

      var connection = this.server.getConnection(id);
      connection.send(this.outgoingQueues[id]);
      this.outgoingQueues[id] = [];
    }
  },

  addEntity: function (entity, callback) {
    this.entities[entity.id] = entity;
    this.handleEntityGroupMembership(entity, callback);
  },

  removeEntity: function (entity) {
    if (entity.id in this.entities) {
      delete this.entities[entity.id];
    }
    if (entity.id in this.mobs) {
      delete this.mobs[entity.id];
    }
    if (entity.id in this.items) {
      delete this.items[entity.id];
    }

    if (entity.type === "mob") {
      this.clearMobAggroLink(entity);
      this.clearMobHateLinks(entity);
    }

    entity.destroy();
    this.removeFromGroups(entity);
    this.pushToAdjacentGroups(entity.group, entity.despawn());
    this.pushBroadcast(entity.despawn());
    log.debug("Removed " + Types.getKindAsString(entity.kind) + " : " + entity.id);
  },

  addPlayer: function (player, callback) {
    this.players[player.id] = player;

    // maps between db player entities and server entities
    this.playersByDBID[player.getDBEntity()._id] = player;
    this.playersByName[player.name] = player;

    this.outgoingQueues[player.id] = [];
    this.addEntity(player, callback);
  },

  removePlayer: function (player) {
    this.removeEntity(player);
    delete this.playersByDBID[player.getDBEntity()._id];
    delete this.playersByName[player.name];
    delete this.players[player.id];
    delete this.outgoingQueues[player.id];
  },

  getPlayerByID: function (playerID) {
    if (!(playerID in this.players)) {
      return null;
    }

    return this.players[playerID];
  },

  getPlayerByDBID: function (dbID) {
    if (!(dbID in this.playersByDBID)) {
      return null;
    }

    return this.playersByDBID[dbID];
  },

  getPlayerByName: function (name) {
    if (!(name in this.playersByName)) {
      return null;
    }

    return this.playersByName[name];
  },

  addMob: function (mob) {
    this.addEntity(mob);
    this.mobs[mob.id] = mob;
  },

  addNpc: function (kind, x, y) {
    var npc = new Npc('8' + x + '' + y, kind, x, y);
    this.addEntity(npc);
    this.npcs[npc.id] = npc;

    return npc;
  },

  addItem: function (item) {
    this.addEntity(item);
    this.items[item.id] = item;

    return item;
  },

  createItem: function (kind, x, y) {
    var id = '9' + this.itemCount++,
      item = null;

    if (kind === Types.Entities.CHEST) {
      item = new Chest(id, x, y);
    } else {
      item = new Item(id, kind, x, y);
    }
    return item;
  },

  createChest: function (x, y, items) {
    var chest = this.createItem(Types.Entities.CHEST, x, y);
    chest.setItems(items);
    return chest;
  },

  addStaticItem: function (item) {
    item.isStatic = true;
    item.on("Respawn", this.addStaticItem.bind(this, item));

    return this.addItem(item);
  },

  addItemFromChest: function (kind, x, y) {
    var item = this.createItem(kind, x, y);
    item.isFromChest = true;

    return this.addItem(item);
  },

  /**
   * The mob will no longer be registered as an attacker of its current target.
   */
  clearMobAggroLink: function (mob) {
    var player = null;
    if (mob.target) {
      player = this.getEntityById(mob.target);
      if (player) {
        player.removeAttacker(mob);
      }
    }
  },

  clearMobHateLinks: function (mob) {
    if (!mob) {
      return;
    }

    _.each(mob.hatelist, function (obj) {
      var player = this.getEntityById(obj.id);
      if (player) {
        player.removeHater(mob);
      }
    }.bind(this));
  },

  forEachEntity: function (callback) {
    for (var id in this.entities) {
      callback(this.entities[id]);
    }
  },

  forEachPlayer: function (callback) {
    for (var id in this.players) {
      callback(this.players[id]);
    }
  },

  forEachMob: function (callback) {
    for (var id in this.mobs) {
      callback(this.mobs[id]);
    }
  },

  forEachCharacter: function (callback) {
    this.forEachPlayer(callback);
    this.forEachMob(callback);
  },

  handleMobHate: function (mobId, playerId, hatePoints) {
    var mob = this.getEntityById(mobId),
      player = this.getEntityById(playerId),
      mostHated;

    if (player && mob) {
      mob.increaseHateFor(playerId, hatePoints);
      player.addHater(mob);

      if (mob.hp > 0) { // only choose a target if still alive
        this.chooseMobTarget(mob);
      }
    }
  },

  chooseMobTarget: function (mob, hateRank) {
    var player = this.getEntityById(mob.getHatedPlayerId(hateRank));

    // If the mob is not already attacking the player, create an attack link between them.
    if (player && !(mob.id in player.attackers)) {
      this.clearMobAggroLink(mob);

      player.addAttacker(mob);
      mob.setTarget(player);

      this.broadcastAttacker(mob);
      log.debug(mob.id + " is now attacking " + player.id);
    }
  },

  // Called when an entity is attacked by another entity
  entityAttack: function (attacker) {
    var target = this.getEntityById(attacker.target);
    if (target && attacker.type === "mob") {
      var pos = this.findPositionNextTo(attacker, target);
      this.moveEntity(attacker, pos.x, pos.y);
    }
  },

  getEntityById: function (id, noError) {
    if (id in this.entities) {
      return this.entities[id];
    } else if (!noError) {
      log.error("Unknown entity : " + id);
    }
  },

  getPlayerCount: function () {
    var count = 0;
    for (var p in this.players) {
      if (this.players.hasOwnProperty(p)) {
        count += 1;
      }
    }
    return count;
  },

  broadcastAttacker: function (character) {
    if (character)  {
      this.pushToAdjacentGroups(character.group, character.attack(), character.id);
      this.entityAttack(character);
    }
  },

  handleHurtEntity: function (entity, attacker, damage) {
    entity.combat();

    this.pushToAdjacentGroups(entity.group, new Messages.Health(entity));
    this.pushToAdjacentGroups(entity.group, new Messages.Damage(entity, damage, attacker));

    // If the entity is about to die
    if (entity.hp <= 0) {
      if (entity.type === "mob") {
        var mob = entity,
          item = this.getDroppedItem(mob);

        attacker.killed(mob);

        this.pushToAdjacentGroups(mob.group, mob.despawn()); // Despawn must be enqueued before the item drop
        if (item) {
          this.pushToAdjacentGroups(mob.group, mob.drop(item));
          this.handleItemDespawn(item);
        }
      }

      if (entity.type === "player") {
        this.handlePlayerVanish(entity);
        this.decrementPlayerCount();
      }

      this.removeEntity(entity);
    }
  },

  despawn: function (entity) {
    this.pushToAdjacentGroups(entity.group, entity.despawn());

    if (entity.id in this.entities) {
      this.removeEntity(entity);
    }
  },

  spawnStaticEntities: function () {
    var count = 0;

    _.each(this.map.staticEntities, function (kindName, tid) {
      var kind = Types.getKindFromString(kindName),
          pos = this.map.tileIndexToGridPosition(tid);

      if (Types.isNpc(kind)) {
        this.addNpc(kind, pos.x + 1, pos.y);
        return;
      }

      if (Types.isMob(kind)) {
        var mob = new Mob('7' + kind + count++, kind, pos.x + 1, pos.y);

        mob.on("Respawn", function () {
          mob.isDead = false;
          this.addMob(mob);
          if (mob.area && mob.area instanceof ChestArea) {
            mob.area.addToArea(mob);
          }
        }.bind(this));

        mob.on("Move", function (mob) {
          this.pushToAdjacentGroups(mob.group, new Messages.Move(mob));
          this.handleEntityGroupMembership(mob);
        }.bind(this));

        this.addMob(mob);
        this.tryAddingMobToChestArea(mob);
        return;
      }

      if (Types.isItem(kind)) {
        this.addStaticItem(this.createItem(kind, pos.x + 1, pos.y));
        return;
      }
    }.bind(this));
  },

  isValidPosition: function (x, y) {
    if (this.map && _.isNumber(x) && _.isNumber(y) && !this.map.isOutOfBounds(x, y) && !this.map.isColliding(x, y)) {
      return true;
    }
    return false;
  },

  handlePlayerVanish: function (player) {
    var previousAttackers = [];

    // When a player dies or teleports, all of his attackers go and attack their second most hated player.
    player.forEachAttacker(function (mob) {
      previousAttackers.push(mob);
      this.chooseMobTarget(mob, 2);
    }.bind(this));

    _.each(previousAttackers, function (mob) {
      player.removeAttacker(mob);
      mob.clearTarget();
      mob.forgetPlayer(player.id, 1000);
    });

    this.handleEntityGroupMembership(player);
  },

  setPlayerCount: function (count) {
    this.playerCount = count;
    this.updatePopulation();
  },

  incrementPlayerCount: function () {
    this.setPlayerCount(this.playerCount + 1);
  },

  decrementPlayerCount: function () {
    if (this.playerCount > 0) {
      this.setPlayerCount(this.playerCount - 1);
    }
  },

  getDroppedItem: function (mob) {
    var kind = Types.getKindAsString(mob.kind),
      drops = Properties[kind].drops,
      v = Utils.random(100),
      p = 0,
      item = null;

    for (var itemName in drops) {
      var percentage = drops[itemName];

      p += percentage;
      if (v <= p) {
        item = this.addItem(this.createItem(Types.getKindFromString(itemName), mob.x, mob.y));
        break;
      }
    }

    return item;
  },

  findPositionNextTo: function (entity, target) {
    var valid = false,
      pos;

    while (!valid) {
      pos = entity.getPositionNextTo(target);
      valid = this.isValidPosition(pos.x, pos.y);
    }
    return pos;
  },

  initZoneGroups: function () {
    this.map.forEachGroup(function (id) {
      this.groups[id] = {
        entities: {},
        players: [],
        incoming: []
      };
    }.bind(this));
    this.zoneGroupsReady = true;
  },

  removeFromGroups: function (entity) {
    if (!entity || !entity.group) {
      return [];
    }

    var oldGroups = [];
    var group = this.groups[entity.group];
    if (entity instanceof Player) {
      group.players = _.reject(group.players, function (id) {
        return id === entity.id;
      }.bind(this));
    }

    this.map.forEachAdjacentGroup(entity.group, function (id) {
      if (entity.id in this.groups[id].entities) {
        delete this.groups[id].entities[entity.id];
        oldGroups.push(id);
      }
    }.bind(this));
    entity.group = null;
    return oldGroups;
  },

  /**
   * Registers an entity as "incoming" into several groups, meaning that it just entered them.
   * All players inside these groups will receive a Spawn message when WorldServer.processGroups is called.
   */
  addAsIncomingToGroup: function (entity, groupId) {
    if (!entity) {
      return;
    }

    var isChest = entity instanceof Chest;
    var isItem = entity instanceof Item;
    var isDroppedItem = isItem && !entity.isStatic && !entity.isFromChest;

    if (!groupId) {
      return;
    }

    this.map.forEachAdjacentGroup(groupId, function (id) {
      var group = this.groups[id];
      if (!group) {
        return;
      }

      //  Items dropped off of mobs are handled differently via DROP messages. See handleHurtEntity.
      if (!_.include(group.entities, entity.id)
          && (
              !isItem 
              || isChest 
              || (isItem && !isDroppedItem)
             )
         ) {
        group.incoming.push(entity);
      }
    }.bind(this));
  },

  addToGroup: function (entity, groupId, callback) {
    var newGroups = [];

    if (entity && groupId && (groupId in this.groups)) {
      this.map.forEachAdjacentGroup(groupId, function (id) {
        this.groups[id].entities[entity.id] = entity;
        newGroups.push(id);
      }.bind(this));
      entity.group = groupId;

      if (entity instanceof Player) {
        this.groups[groupId].players.push(entity.id);
      }
    }

    if (callback) {
      callback();
    }

    return newGroups;
  },

  logGroupPlayers: function (groupId) {
    log.debug("Players inside group " + groupId + ":");
    _.each(this.groups[groupId].players, function (id) {
      log.debug("- player " + id);
    });
  },

  handleEntityGroupMembership: function (entity, callback) {
    if (!entity) {
      return false;
    }

    var hasChangedGroups = false;
    var groupId = this.map.getGroupIdFromPosition(entity.x, entity.y);
    if (!entity.group || (entity.group && entity.group !== groupId)) {
      hasChangedGroups = true;
      this.addAsIncomingToGroup(entity, groupId);
      var oldGroups = this.removeFromGroups(entity);
      var newGroups = this.addToGroup(entity, groupId, callback);

      if (_.size(oldGroups) > 0) {
        entity.recentlyLeftGroups = _.difference(oldGroups, newGroups);
        log.debug("group diff: " + entity.recentlyLeftGroups);
      }
    }

    return hasChangedGroups;
  },

  processGroups: function () {
    if (!this.zoneGroupsReady) {
      return;
    }

    this.map.forEachGroup(function (id) {
      var spawns = [];
      if (this.groups[id].incoming.length > 0) {
        spawns = _.each(this.groups[id].incoming, function (entity) {
          if (entity instanceof Player) {
            this.pushToGroup(id, new Messages.Spawn(entity), entity.id);
            return;
          }

          this.pushToGroup(id, new Messages.Spawn(entity));
        }.bind(this));
        this.groups[id].incoming = [];
      }
    }.bind(this));
  },

  moveEntity: function (entity, x, y) {
    if (!entity) {
      return;
    }

    entity.setPosition(x, y);
    this.handleEntityGroupMembership(entity);
  },

  handleItemDespawn: function (item) {
    if (!item) {
      return;
    }

    item.handleDespawn({
      beforeBlinkDelay: 10000,
      blinkCallback: function () {
        this.pushToAdjacentGroups(item.group, new Messages.Blink(item));
      }.bind(this),
      blinkingDuration: 4000,
      despawnCallback: function () {
        this.removeEntity(item);
      }.bind(this)
    });
  },

  handleEmptyMobArea: function (area) {

  },

  handleEmptyChestArea: function (area) {
    if (!area) {
      return;
    }

    var chest = this.addItem(this.createChest(area.chestX, area.chestY, area.items));
    this.handleItemDespawn(chest);
  },

  handleOpenedChest: function (chest, player) {
    this.removeEntity(chest);

    var kind = chest.getRandomItem();
    if (kind) {
      var item = this.addItemFromChest(kind, chest.x, chest.y);
      this.handleItemDespawn(item);
    }
  },

  tryAddingMobToChestArea: function (mob) {
    _.each(this.chestAreas, function (area) {
      if (area.contains(mob)) {
        area.addToArea(mob);
      }
    });
  },

  updatePopulation: function (totalPlayers) {
    this.pushBroadcast(new Messages.Population(this.playerCount, totalPlayers ? totalPlayers : this.playerCount));
  }
});
