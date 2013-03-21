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
    init: function(player, callback) {
        this.player = null;
        this.dbEntity = null;
        this.items = {};

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

    add: function(item) {
        if (item.isStackable) {
            // find item in the list so we can just increase its amount
            for (var i in this.items) {
               var curItem = this.items[i]; 
               if (item.kind == curItem.kind) {
                   curItem.amount += item.amount;
                   curItem.save();
                   return true;
               }
            }
        }

        // couldn't find it in the inventory, or it isn't stackable.
        // create a new inventory item for it
        //
        // but first, check if we have room for it in the inventory
        log.debug("size: "+this.size);
        if (Object.keys(this.items).length >= this.size) {
            // not enough room!
            return false;
        }

        var newItem = new Items({
            kind: item.kind,
            amount: item.amount,
            inventoryId: this.id
        });
        newItem.save(function(err) {
            if (err) {
                // failed saving new item in inventory
                log.debug("failed saving new item in inventory. Error: "+err);
            } else {
                log.debug("Saved new item in inventory.");
            }
        });

        // place it in the inventory
        this.items[newItem._id] = new InventoryItem(newItem);

        return true;
    },

    remove: function(item) {
        // find item in the list so we can set it to a different
        // inventory id.
        for (var i in this.items) {
           var curItem = this.items[i]; 
           if (item.kind == curItem.kind) {
               curItem.amount -= item.amount;
               if (curItem.amount <= 0) {
                   Items.remove({_id: curItem._id});
                   delete this.items[i];
                   log.debug("Removed item from player's inventory");
               } else {
                   curItem.save(function(err) {
                        if (err) {
                            log.debug("Error saving item in player's inventory after removal from stack of items. Error: "+err);
                        } else {
                            log.debug("Decreased item stack in player's inventory");
                        }
                   });
               }
               return;
           }
        }
    },

    load: function(player, callback) {
        var self = this;
        self.player = player;

        Inventories.findOne({playerId: self.player.getId()}, function(err, dbEntity){
            if (err) {
                log.debug("Failed fetching inventory for player id '"+self.player.getId()+"'. Error: "+err);
                return;
            }

            if (dbEntity) {
                log.debug("Found previous inventory record.");
            } else {
                log.debug("Creating new inventory record for player id '"+self.player.getId()+"'");
                var dbEntity = new Inventories({
                    playerId: self.player.getId(),
                    size: 12
                });
                dbEntity.save(function(err) {
                    if (err) {
                        log.debug("Failed saving inventory for player id '"+self.player.getId()+"'. Error: "+err);
                    }
                });
            }

            self.setDBEntity(dbEntity, callback);
        });
    },

    loadFromDB: function(callback) {
        if (!this.dbEntity) return;
        
        var self = this;

        this._super();
       
        if (!self.data) self.data = {};

        Utils.Mixin(self.data, {
            playerId: self.dbEntity.playerId,
            size: self.dbEntity.size,
            id: self.dbEntity._id
        });

        // load items
        Items.find({inventoryId: self.id}, function(err, items){
            if (err) {
                log.debug("Error loading items for inventory '"+self.id+"'");
                return;
            }

            items.forEach(function(item) {
                self.items[item._id] = new InventoryItem(item);
                log.debug("inventory-item, id: "+item._id+" -- kind:"+item.kind+" -- amount:"+item.amount);
            });

            if (callback) {
                callback();
            }
        });
    },
    
    save: function() {
        if (!this.dbEntity) return;

//        Utils.Mixin(this.dbEntity, this.data);
        this.dbEntity.playerId = this.data.playerId;
        this.dbEntity.size = this.data.size;

        this._super();
    },

    serialize: function() {
        var items = {};
        for (var itemId in this.items) {
            items[itemId] = this.items[itemId].data;
        }

        return [this.size, items];
    },
});
