var cls = require("./lib/class"),
  _ = require("underscore"),
  Messages = require("./message"),
  Utils = require("./utils"),
  Properties = require("./properties"),
  Formulas = require("./formulas"),
  DB = require("./db"),
  DBEntity = require("./db-entity"),
  InventoryItem = require("./inventory-item"),
  Types = require("../../shared/js/gametypes");

module.exports = Inventory = DBEntity.extend({
  init: function (player, callback) {
    this.player = null;
    this.dbEntity = null;
    this.items = new Array();

    if (player) {
      this.player = player;
      this.load(player, callback);
    }
  },

  get id() {
    return this.data.id;
  },

  get size() {
    return this.data.size;
  },

  swap: function (first, second) {
    var temp = this.items[first];
    this.items[first] = this.items[second];
    this.items[second] = temp;

    if (this.items[first]) {
      this.items[first].slot = first;
    }
    if (this.items[second]) {
      this.items[second].slot = second;
    }
  },

  use: function (itemId) {
    // find item with itemId and use it
    for (var i in this.items) {
      var item = this.items[i];
      if (item && item.id == itemId) {
        item.use();
      }
    }
  },

  find: function (itemId) {
    for (var i in this.items) {
      var item = this.items[i];
      if (item && item.id == itemId) {
        return item;
      }
    }

    return null;
  },

  add: function (item) {
    if (item.isStackable) {
      // find item in the list so we can just increase its amount
      for (var i in this.items) {
        var curItem = this.items[i];
        if (curItem && item.kind == curItem.kind) {
          curItem.amount += item.amount;
          curItem.save();
          return curItem;
        }
      }
    }

    // couldn't find it in the inventory, or it isn't stackable.
    // create a new inventory item for it
    //
    // but first, check if we have room for it in the inventory
    if (Object.keys(this.items).length >= this.size) {
      // not enough room!
      return false;
    }

    // find a slot to place the new item at
    var slot = -1;
    //for  (var i in this.items) {
    for (var i = 0; i < this.size; i++) {
      if (!this.items[i]) {
        slot = i;
        break;
      }
    }

    var newItem = null;

    if (item.type == "inventory-item") {
      newItem = item;
    } else {
      var dbEntity = new Items({
        kind: item.kind,
        amount: item.amount,
        inventoryId: this.id,
        slot: slot,
        barSlot: -1
      });

      dbEntity.save(DB.defaultCallback);
      newItem = new InventoryItem(this, dbEntity);
    }

    // place it in the inventory
    this.items[slot] = newItem;
    this.player.syncInventory();
    return newItem;
  },

  load: function (player, callback) {
    var self = this;
    self.player = player;

    Inventories.findOne({
      playerId: self.player.getId()
    }, function (err, dbEntity) {
      if (err) {
        log.debug("Failed fetching inventory for player id '" + self.player.getId() + "'. Error: " + err);
        return;
      }

      if (dbEntity) {
        log.debug("Found previous inventory record.");
      } else {
        log.debug("Creating new inventory record for player id '" + self.player.getId() + "'");
        var dbEntity = new Inventories({
          playerId: self.player.getId(),
          size: 12
        });
        dbEntity.save(function (err) {
          if (err) {
            log.debug("Failed saving inventory for player id '" + self.player.getId() + "'. Error: " + err);
          }
        });
      }

      self.setDBEntity(dbEntity, callback);
    });
  },

  loadFromDB: function (callback) {
    if (!this.dbEntity) return;

    var self = this;

    this._super();

    if (!self.data) self.data = {};

    Utils.Mixin(self.data, {
      playerId: self.dbEntity.playerId,
      size: self.dbEntity.size,
      id: self.dbEntity._id
    });

    self.items = {};

    // load items
    Items.find({
      inventoryId: self.id,
      amount: {
        $gte: 1
      }
    }, function (err, items) {
      if (err) {
        log.debug("Error loading items for inventory '" + self.id + "'");
        return;
      }

      items.forEach(function (item) {
        self.items[item.slot] = new InventoryItem(self, item);
      });

      if (callback) {
        callback();
      }
    });
  },

  save: function () {
    if (!this.dbEntity) return;

    //        Utils.Mixin(this.dbEntity, this.data);
    this.dbEntity.size = this.data.size;
    for (var i in this.items) {
      if (this.items[i]) {
        this.items[i].save();
      }
    }

    this._super();
  },

  serialize: function () {
    var items = {};
    for (var i in this.items) {
      if (this.items[i]) {
        items[i] = this.items[i].getData();
      }
    }

    return [this.size, items];
  },
});
