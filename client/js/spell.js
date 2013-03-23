
define(function() {

    var Spell = Class.extend({
        init: function(kind) {
    	    var self = this;

            this.kind = kind;
            this._cooldown = 1;
            this._castTime = 1;
            this._name = "N/A";
            this._tooltip = "N/A";
    	},

        get cooldown() {
            return this._cooldown;
        },

        get castTime() {
            return this._castTime;
        },

/*
        get name() {
            return this._name;
        },
*/
        get tooltip() {
            return this._tooltip;
        },

        get spellKind() {
            return Types.getKindAsString(this.kind);
        },

        getSpriteName: function() {
            return "spell-"+this.spellKind;
        },

        use: function(target) {
            globalGame.client.sendUseSpell(this);

            if (target) {
                console.log("Used %s on %s", this.spellKind, target.name);
            } else {
                console.log("Used %s", this.spellKind);
            }
        }
    });
    
    return Spell;
});
