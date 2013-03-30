
define(['entity'], function(Entity) {

    var Chest = Entity.extend({
        init: function(id, kind) {
    	    this._super(id, Types.Entities.CHEST);
        },
    
        getSpriteName: function() {
            return "chest";
        },
    
        isMoving: function() {
            return false;
        },
    
        open: function() {
            this.stopBlinking();
            this.setSprite(globalGame.sprites["death"]);

            var self = this;
            this.setAnimation("death", 120, 1, function() {
                log.info(self.id + " was removed");
                globalGame.removeEntity(self);
                globalGame.removeFromRenderingGrid(self, self.gridX, self.gridY);
                globalGame.previousClickPosition = {};
            });
        }
    });
    
    return Chest;
});
