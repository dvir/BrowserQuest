define(['spell',
        '../../shared/js/gametypes'], function(
        Spell,
        config) {
    
    var Spells = {
        frostnova: Spell.extend({
            init: function(target){
                this._super(Types.Entities.FROSTNOVA, target);
                this.spellType = "aoe";
            },
        }),
        frostbolt: Spell.extend({
            init: function(target){
                this._super(Types.Entities.FROSTBOLT, target);
                this.spellType = "single";
            },
        }),
        fireball: Spell.extend({
            init: function(target){
                this._super(Types.Entities.FIREBALL, target);
                this.spellType = "directional";
            },
        }),
        icebarrier: Spell.extend({
            init: function(target){
                this._super(Types.Entities.ICEBARRIER, target);
                this.spellType = "directional";
            },
        }),
        polymorph: Spell.extend({
            init: function(target){
                this._super(Types.Entities.POLYMORPH, target);
                this.spellType = "directional";
            },
        }),
        blink: Spell.extend({
            init: function(target){
                this._super(Types.Entities.BLINK, target);
                this.spellType = "directional";
            },
        }),
        getSpell: function(kind, target) {
            console.log(Types.getKindAsString(kind));
            return new this[Types.getKindAsString(kind)](target);
        },
    };

    return Spells;
});
