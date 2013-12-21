define(['entity'], function (Entity) {

  var Item = Entity.extend({
    init: function (id, kind) {
      this._super(id, kind);

      this.wasDropped = false;

      this.amount = 1;

      this._cooldown = 1;
      this._castTime = 1;
      this._tooltip = "N/A";
      this.nameOffsetY += 5;
    },

    get cooldown() {
      return this._cooldown;
    },

    get castTime() {
      return this._castTime;
    },

    get tooltip() {
      return this._tooltip;
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

    hasShadow: function () {
      return true;
    },

    onLoot: function (player) {
      if (this.type === "weapon") {
        player.lootedWeapon(this);
      } else if (this.type === "armor") {
        player.lootedArmor(this);
      }
    },

    getSpriteName: function () {
      return "item-" + this.itemKind;
    },

    getLootMessage: function () {
      return this.lootMessage;
    }
  });

  return Item;
});
