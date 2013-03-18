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
            x: 0,
            y: 0
        });

        if (dbEntity) {
            this.setDBEntity(dbEntity);
        }
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

    loadFromDB: function() {
        if (!this.dbEntity) return;
        
        this._super();
        
        Utils.Mixin(this.data, {
            kind: this.dbEntity.kind,
            amount: this.dbEntity.amount,
            inventoryId: this.dbEntity.inventoryId,
            x: this.dbEntity.x,
            y: this.dbEntity.y
        });
    },

    save: function() {
        if (!this.dbEntity) return;

//        Utils.Mixin(this.dbEntity, this.data);
        this.dbEntity.kind = this.data.kind;
        this.dbEntity.amount = this.data.amount;
        this.dbEntity.inventoryId = this.data.inventoryId;
        this.dbEntity.x = this.data.x;
        this.dbEntity.y = this.data.y;

        this._super();
    }
});
