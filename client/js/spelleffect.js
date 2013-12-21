define(['entity'], function (Entity) {

  var SpellEffect = Entity.extend({
    init: function (id, kind) {
      this._super(id, kind);
    },

    get name() {
      return null;
    },

    get spellEffectKind() {
      return Types.getKindAsString(this.kind);
    },

    getSpriteName: function () {
      return "spell-" + this.spellEffectKind;
    }
  });

  return SpellEffect;
});
