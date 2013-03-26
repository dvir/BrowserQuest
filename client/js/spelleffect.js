
define(['entity', 'item'], function(Entity, Item) {

    var SpellEffect = Entity.extend({
        init: function(id, kind) {
    	    this._super(id, kind);
        },

        get spellEffectKind() {
            return Types.getKindAsString(this.kind);
        },

        getSpriteName: function() {
            return "spell-"+ this.spellEffectKind;
        },
    });
    
    return SpellEffect;
});
