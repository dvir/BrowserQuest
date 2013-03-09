
define(['entity'], function(Entity) {

    var Item = Entity.extend({
        init: function(id, kind, type) {
    	    this._super(id, kind);

            this.itemKind = Types.getKindAsString(kind);
    	    this.type = type;
    	    this.wasDropped = false;
        },

        hasShadow: function() {
            return true;
        },

        onLoot: function(player) {
            if(this.type === "weapon") {
//                player.switchWeapon(this.itemKind);
                player.lootedWeapon(this);
            }
            else if(this.type === "armor") {
//                player.armorloot_callback(this.itemKind);
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
