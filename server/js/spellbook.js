var cls = require("./lib/class"),
  _ = require("underscore"),
  Messages = require("./message"),
  Utils = require("./utils"),
  Properties = require("./properties"),
  Formulas = require("./formulas"),
  DB = require("./db"),
  Spells = require("./spells"),
  Types = require("../../shared/js/gametypes");

module.exports = Spellbook = Class.extend({
  init: function (player, callback) {
    this.player = null;
    this.spells = [];

    if (player) {
      this.load(player, callback);
    }
  },

  use: function (spellId, target, orientation, trackingId) {
    // find spell with spellId and use it

    var spell = Spells.getSpell(Types.getKindAsString(spellId), trackingId);
    spell.id = trackingId;
    if (!spell) {
      log.debug("Unknown spell '" + spellId + "'");
      return false;
    }

    spell.use(this.player.server, this.player, target, orientation);
    return true;
  },

  find: function (spellId) {
    for (var i in this.spells) {
      var spell = this.spells[i];
      if (spell.id == spellId) {
        return spell;
      }
    }

    return null;
  },

  add: function (spell) {
    this.spells.push(spell);
  },

  remove: function (spell) {
    for (var i in this.spells) {
      if (spell == this.spells[i]) {
        this.spells.splice(i, 1);
        return true;
      }
    }

    return false;
  },

  load: function (player, callback) {
    this.player = player;

    this.update();

    if (callback) {
      callback();
    }
  },

  update: function () {
    return;

    var spells = Types.getSpells(this.player.level, this.player.kind);
    this.spells = _.map(spells, function (spellId) {
      return new Spell(spellId);
    });
  },

  serialize: function () {
    return _.map(this.spells, function (spell) {
      return spell.serialize();
    });
  },
});
