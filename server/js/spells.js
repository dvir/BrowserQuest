
var Spell = require("./spell");

module.exports = Spells = {
   frostnova: Spell.extend({
        init: function(id){
            this._super(Types.Entities.FROSTNOVA, id);

            this.spellType = "aoe";
            this._radius = 3;
            this._type = "frost";
            this._dmg = {low: 10, high: 20};
            this._range  = 0;
        },
   }),

   frostbolt: Spell.extend({
        init: function(id){
            this._super(Types.Entities.FROSTBOLT);

            this.spellType = "single";
            this._type = "frost";
            this._dmg = {low: 40, high: 60};
            this._range = 10;
            this._radius = 0.5;
        },
   }),

   fireball: Spell.extend({
        init: function(id){
            this._super(Types.Entities.FIREBALL);

            this.spellType = "directional";
            this._type = "fire";
            this._dmg = {low: 45, high: 80};
            this._range = 10;
            this._radius = 0.5;
        },
   }),

   getSpell: function(name, id) {
        return new this[name](id);
   }
};
