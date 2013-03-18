
define(['entity'], function(Entity) {

    var Item = Entity.extend({
        init: function(id, kind) {
    	    this._super(id, kind);

    	    this.wasDropped = false;

            this.amount = 1;
        },

        get itemKind() {
            return Types.getKindAsString(this.kind);
        },

        get type() {
            return Types.getType(this.kind);
        },

        get isStackable() {
            return Types.isStackable(this.kind);
        },

        hasShadow: function() {
            return true;
        },

        onLoot: function(player) {
            if(this.type === "weapon") {
                player.lootedWeapon(this);
            }
            else if(this.type === "armor") {
                player.lootedArmor(this);
            }
        },

        getSpriteName: function() {
            return "item-"+ this.itemKind;
        },

        getLootMessage: function() {
            return this.lootMessage;
        }
    });
    
    return Item;
});
