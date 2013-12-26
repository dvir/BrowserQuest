define(['entity'], function (Entity) {

  var Chest = Entity.extend({
    init: function (id, kind) {
      this._super(id, Types.Entities.CHEST);
      this._name = "Chest";
    },

    getSpriteName: function () {
      return "chest";
    },

    isMoving: function () {
      return false;
    },

    open: function () {
      this.stopBlinking();
      this.setSprite(globalGame.sprites["death"]);

      this.setAnimation("death", 120, 1, function () {
        log.info(this.id + " was removed");
        globalGame.removeEntity(this);
        globalGame.removeFromRenderingGrid(this, this.gridX, this.gridY);
        globalGame.previousClickPosition = {};
      }.bind(this));
    }
  });

  return Chest;
});
