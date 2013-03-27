
var cls = require("./lib/class"),
    Messages = require('./message'),
    Utils = require('./utils'),
    Formulas = require("./formulas"),
    Types = require("../../shared/js/gametypes");

module.exports = Spell = Entity.extend({
    init: function(kind, id) {
        this._super(id, "spell", kind, 0, 0);

        this._type = "none";
        this._dmg = {low: 0, high: 0};
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

    use: function(server, attacker, target, orientation) {
        if (this.spellType == "single") {
            if ((!(target instanceof Mob)) 
                || attacker.distanceTo(target) > this.range) 
            {
                return false;
            }

            var dmg = this.dmg;
            target.receiveDamage(dmg, attacker.id);
            server.handleMobHate(target.id, attacker.id, dmg);
            server.handleHurtEntity(target, attacker, dmg);
        } else if (this.spellType == "directional") {
            var self = this;
            server.addEntity(self);
            server.moveEntity(self, attacker.x, attacker.y);
            self.travelDistance = 0;
            self.interval = setInterval(function(){
                if (self.travelDistance > self.range) {
                    clearInterval(self.interval);
                    clearTimeout(self.timeout);
                    server.removeEntity(self);
                    return;
                }

                if (server.groups[self.group]) {
                    var entities = server.groups[self.group].entities;

                    entities = _.reject(entities, function(entity) {
                        return (!(entity instanceof Mob)) 
                               || self.distanceTo(entity) > self.radius;
                    });

                    if (_.size(entities) > 0) {
                        var entity = _.min(entities, function(entity) {
                            return self.distanceTo(entity);
                        });

                        var dmg = self.dmg;
                        entity.receiveDamage(dmg, attacker.id);
                        server.handleMobHate(entity.id, attacker.id, dmg);
                        server.handleHurtEntity(entity, attacker, dmg);

                        clearInterval(self.interval);
                        clearTimeout(self.timeout);
                        server.removeEntity(self);
                        return;
                    }
                }
                
                var pos = self.moveSteps(1, orientation);
                server.moveEntity(self, pos.x, pos.y);
                self.travelDistance++;
            }, 80);

            self.timeout = setTimeout(function(){
                clearInterval(self.interval);
                server.removeEntity(self);
            }, 3000);
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

            var entities = server.groups[centerEntity.group].entities;

            entities = _.reject(entities, function(entity) {
                return (!(entity instanceof Mob)) 
                       || centerEntity.distanceTo(entity) > radius;
            });

            var self = this;
            _.forEach(entities, function(entity){
                var dmg = self.dmg;
                entity.receiveDamage(dmg, attacker.id);
                server.handleMobHate(entity.id, attacker.id, dmg);
                server.handleHurtEntity(entity, attacker, dmg);
            });
        }

        return true;
    }
});
