var Entity = require("./entity"),
    _ = require("underscore"),
    Utils = require("./utils"),
    Properties = require("./properties"),
    DB = require("./db"),
    Types = require("../../shared/js/gametypes");

module.exports = InventoryItem = Entity.extend({
    init: function(inventory, dbEntity) {
        this._super(0, "inventory-item", Types.Entities.UNKNOWN, 0, 0);
        
        this.inventory = inventory;
        this.player = inventory.player;
        this.isStatic = false;
        this.isFromChest = false;
        
        Utils.Mixin(this.data, {
            id: 0,
            amount: 1,
            kind: Types.Entities.UNKNOWN,
            inventoryId: 0,
            slot: -1,
            barSlot: -1
        });

        if (dbEntity) {
            this.setDBEntity(dbEntity);
        }
    },

    use: function(target) {
        if (this.kind === Types.Entities.FIREPOTION) {
            this.player.broadcast(this.player.equip(Types.Entities.FIREFOX));
            this.amount--;
            var self = this;
            this.player.firepotionTimeout = setTimeout(function() {
                // return to normal after 15 sec
                self.player.broadcast(self.player.equip(self.player.armor)); 
                self.player.firepotionTimeout = null;
            }, 15000);
        } else if (Types.isHealingItem(this.kind)) {
            var amount;
            
            switch (this.kind) {
                case Types.Entities.FLASK: 
                    amount = 40;
                    break;
                case Types.Entities.BURGER: 
                    amount = 100;
                    break;
            }
            
            if (!this.player.hasFullHealth()) {
                this.amount--;

                this.player.regenHealthBy(amount);
                this.player.broadcast(this.player.health());
            }
        } else if (Types.isArmor(this.kind) || Types.isWeapon(this.kind)) {
            var oldKind = this.equip(); 
            this.remove();
            this.inventory.add(this.player.server.createItem(oldKind, 0, 0));
        }
    },

    equip: function() {
        log.debug(this.player.name + " equips " + Types.getKindAsString(this.kind));
    
        var oldKind = null;
        if(Types.isArmor(this.kind)) {
            oldKind = this.player.armor;
            this.player.armor = this.kind;
        } else if(Types.isWeapon(this.kind)) {
            oldKind = this.player.weapon;
            this.player.weapon = this.kind;
        } else {
            log.debug("Cannot equip item of kind '"+this.kind+"'");
            return false;
        }

        this.player.broadcast(this.player.equip(this.kind));
        return oldKind;
    },

    get id() {
        return this.data.id;
    },

    get kind() {
        return this.data.kind;
    },

    get amount() {
        return this.data.amount;
    },

    set amount(amount) {
        this.data.amount = amount;
        this.isDirty = true;
        this.save();
    },

    get inventoryId() {
        return this.data.inventoryId;
    },

    get slot() {
        return this.data.slot;
    },

    set slot(slot) {
        this.data.slot = slot;
        this.isDirty = true;
        this.save();
    },

    get isStackable() {
        return Types.isStackable(this.kind);
    },

    get useOnPick() {
        return Types.isUseOnPickup(this.kind);
    },

    getData: function() {
        var data = this.data;
    //    delete data.inventoryId;
        return data;
    },

    loadFromDB: function() {
        if (!this.dbEntity) return;
        
        this._super();
        
        Utils.Mixin(this.data, {
            id: this.dbEntity._id,
            kind: this.dbEntity.kind,
            amount: this.dbEntity.amount,
            inventoryId: this.dbEntity.inventoryId,
            slot: this.dbEntity.slot,
            barSlot: this.dbEntity.barSlot
        });
    },

    remove: function() {
        this.amount = 0;
    },

    save: function(callback) {
        if (!this.dbEntity || !this.isDirty) return;

//        Utils.Mixin(this.dbEntity, this.data);
        this.dbEntity.kind = this.data.kind;
        this.dbEntity.amount = this.data.amount;
        this.dbEntity.inventoryId = this.data.inventoryId;
        this.dbEntity.slot = this.data.slot;
        this.dbEntity.barSlot = this.data.barSlot;

        var self = this;
        this._super(function(){
            self.inventory.loadFromDB(function(){
                self.inventory.player.syncInventory();

                if (callback) {
                    callback();
                }
            });
        });
    }
});
