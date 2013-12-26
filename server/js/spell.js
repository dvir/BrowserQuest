var cls = require("./lib/class"),
  Messages = require('./message'),
  Utils = require('./utils'),
  Formulas = require("./formulas"),
  Types = require("../../shared/js/gametypes");

module.exports = Spell = Entity.extend({
  init: function (kind, id) {
    this._super(id, "spell", kind, 0, 0);

    this._type = "none";
    this._dmg = {
      low: 0,
      high: 0
    };
    this._radius = 0;
    this._range = 1;
    this.x = 0;
    this.y = 0;
    this.targets = {};
  },

  get type() {
    return this._type;
  },

  get dmg() {
    return Math.round(this._dmg.high - ((this._dmg.high - this._dmg.low) * Math.random()));
  },

  get radius() {
    return this._radius;
  },

  get range() {
    return this._range;
  },

  use: function (server, attacker, target, orientation) {
    if (this.spellType == "single") {
      if ((!(target instanceof Mob)) || attacker.distanceTo(target) > this.range) {
        return false;
      }

      var dmg = this.dmg;
      target.receiveDamage(dmg, attacker.id);
      server.handleMobHate(target.id, attacker.id, dmg);
      server.handleHurtEntity(target, attacker, dmg);
    } else if (this.spellType == "directional") {
      server.addEntity(this);
      server.moveEntity(this, attacker.x, attacker.y);
      this.travelDistance = 0;
      this.interval = setInterval(function () {
        if (this.travelDistance > this.range) {
          clearInterval(this.interval);
          clearTimeout(this.timeout);
          server.removeEntity(this);
          return;
        }

        if (server.groups[this.group]) {
          var entities = server.groups[this.group].entities;

          entities = _.reject(entities, function (entity) {
            return (!(entity instanceof Mob)) || this.distanceTo(entity) > this.radius;
          }.bind(this));

          if (_.size(entities) > 0) {
            var entity = _.min(entities, function (entity) {
              return this.distanceTo(entity);
            }.bind(this));

            var dmg = this.dmg;
            entity.receiveDamage(dmg, attacker.id);
            server.handleMobHate(entity.id, attacker.id, dmg);
            server.handleHurtEntity(entity, attacker, dmg);

            clearInterval(this.interval);
            clearTimeout(this.timeout);
            server.removeEntity(this);
            return;
          }
        }

        var pos = this.moveSteps(1, orientation);
        server.moveEntity(this, pos.x, pos.y);
        this.travelDistance++;
      }.bind(this), 80);

      this.timeout = setTimeout(function () {
        clearInterval(this.interval);
        server.removeEntity(this);
      }.bind(this), 3000);
    } else if (this.spellType == "aoe") {
      // area of effect 
      // there are two options - AOE around attacker, or AOE around target
      // range == 0 indicates AOE around attacker

      var radius = this.radius;
      var centerEntity = attacker;
      if (this.range != 0) {
        // AOE around target
        centerEntity = target;

        // make sure target is close enough
        if (attacker.distanceTo(target) > this.range) {
          return false;
        }
      }

      if (!centerEntity.group || !server.groups[centerEntity.group]) {
        return false;
      }

      var entities = server.groups[centerEntity.group].entities;

      entities = _.reject(entities, function (entity) {
        return (!(entity instanceof Mob)) || centerEntity.distanceTo(entity) > radius;
      });

      var dmg = this.dmg;
      _.forEach(entities, function (entity) {
        entity.receiveDamage(dmg, attacker.id);
        server.handleMobHate(entity.id, attacker.id, dmg);
        server.handleHurtEntity(entity, attacker, dmg);
      });
    }

    return true;
  }
});
