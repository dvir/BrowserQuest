define(['spelleffect',
  'items',
  'entity',
  'mob'
], function (
  SpellEffect,
  Items,
  Entity,
  Mob) {

  var Spell = Class.extend({
    init: function (kind, target) {
      var self = this;

      this.kind = kind;
      this._cooldown = 1;
      this._castTime = 1;
      this._name = "N/A";
      this._tooltip = "N/A";
      this.spellType = "single";
      this.type = "spell";
      this.id = Math.floor(Math.random() * 100000 + 100000);

      this.target = target;
    },

    getEffect: function () {
      return (new SpellEffect(null, this.kind));
    },

    get cooldown() {
      return this._cooldown;
    },

    get castTime() {
      return this._castTime;
    },

    get name() {
      return this._name;
    },

    get tooltip() {
      return this._tooltip;
    },

    get spellKind() {
      return Types.getKindAsString(this.kind);
    },

    getSpriteName: function () {
      return "icon-spell-" + this.spellKind;
    },

    use: function (target) {
      this.target = target;
      var orientation = globalGame.player.orientation;
      var trackingId = null;

      if (this.spellType == "single") {
        // maybe apply sparks to the target?
      } else if (this.spellType == "directional") {
        var effect = this.getEffect();
        effect.interactable = false;
        trackingId = effect.id;
        globalGame.addSpellEffect(effect, globalGame.player.gridX, globalGame.player.gridY);
        effect.interval = setInterval(function () {
          effect.moveSteps(1, orientation);
        }, 80);

        effect.timeout = setTimeout(function () {
          clearInterval(effect.interval);
          globalGame.removeSpellEffect(effect);
        }, 3000);
      } else if (this.spellType == "aoe") {
        // get a big rounded(squared?) item to show
      }

      globalGame.client.sendUseSpell(this, target, orientation, trackingId);

      if (target) {
        console.log("Used %s on %s", this.spellKind, target.name);
      } else {
        console.log("Used %s", this.spellKind);
      }
    },

    draw: function (context, tilesize, scale) {
      console.log("trying to draw...");
      var radius = 90;
      var dx = this.target.x * scale;
      var dy = this.target.y * scale;
      context.save();
      context.globalAlpha = 0.3;
      context.translate(dx, dy);
      context.beginPath();
      context.arc(tilesize, tilesize, radius, 0, 2 * Math.PI, false);
      context.fillStyle = 'rgba(0,0,200,0.5)';
      context.fill();
      context.lineWidth = 2;
      context.strokeStyle = 'rgba(0,0,0,0.5)';
      context.stroke();
      context.restore();
    },
  });

  return Spell;
});
