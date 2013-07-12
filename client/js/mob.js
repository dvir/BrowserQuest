
define(['character', 'player'], function(Character) {
    
    var Mob = Character.extend({
        init: function(id, kind) {
            this._super(id, kind);

            this.targetable = true;
            this.aggroRange = 1;
            this.isAggressive = true;
        },
        
        isHostile: function(entity) {
            // @TODO: implement!
            return (entity instanceof Player);
        },

    	die: function() {
            // Keep track of where mobs die in order to spawn their dropped items
            // at the right position later.
            globalGame.deathpositions[this.id] = {x: this.gridX, y: this.gridY};

            this._super();
    	},
    });
    
    return Mob;
});
