var Entity = require("./entity"),
    _ = require("underscore"),
    Utils = require("./utils"),
    Properties = require("./properties"),
    DB = require("./db"),
    Types = require("../../shared/js/gametypes");

module.exports = InventoryItem = Entity.extend({
    init: function(dbEntity) {
        this._super(0, "inventory-item", Types.Entities.UNKNOWN, 0, 0);
        
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

    use: function() {
        
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
        this.save();
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

    save: function() {
        if (!this.dbEntity) return;

//        Utils.Mixin(this.dbEntity, this.data);
        this.dbEntity.kind = this.data.kind;
        this.dbEntity.amount = this.data.amount;
        this.dbEntity.inventoryId = this.data.inventoryId;
        this.dbEntity.slot = this.data.slot;
        this.dbEntity.barSlot = this.data.barSlot;

        this._super();
    }
});
