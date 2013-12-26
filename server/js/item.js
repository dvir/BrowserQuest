var Messages = require('./message');

module.exports = Item = Entity.extend({
  init: function (id, kind, x, y, amount) {
    this._super(id, "item", kind, x, y);
    this.isStatic = false;
    this.isFromChest = false;
    this.isStackable = Types.isStackable(kind);
    this.useOnPickup = Types.isUseOnPickup(kind);
    this.amount = Utils.isNumber(amount) ? amount : 1;
  },

  isBetterThan: function (other) {
    return Types.itemRankCompare(this, other);
  },

  handleDespawn: function (params) {
    var self = this;

    this.blinkTimeout = setTimeout(function () {
      params.blinkCallback();
      self.despawnTimeout = setTimeout(params.despawnCallback, params.blinkingDuration);
    }, params.beforeBlinkDelay);
  },

  destroy: function () {
    if (this.blinkTimeout) {
      clearTimeout(this.blinkTimeout);
    }
    if (this.despawnTimeout) {
      clearTimeout(this.despawnTimeout);
    }

    if (this.isStatic) {
      this.scheduleRespawn(30000);
    }
  },

  despawn: function () {
    return new Messages.Destroy(this);
  },

  scheduleRespawn: function (delay) {
    var self = this;
    setTimeout(function () {
      if (self.respawn_callback) {
        self.respawn_callback();
      }
    }, delay);
  },

  onRespawn: function (callback) {
    this.respawn_callback = callback;
  }
});
