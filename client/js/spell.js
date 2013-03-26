
define(['spelleffect',
        'items',
        'mob'], function(
         SpellEffect,
         Items,
         Mob) {

    var Spell = Class.extend({
        init: function(kind, target) {
    	    var self = this;

            this.kind = kind;
            this._cooldown = 1;
            this._castTime = 1;
            this._name = "N/A";
            this._tooltip = "N/A";
            this.spellType = "single";
            this.type = "spell";
            this.id = Math.floor(Math.random()*100000+100000);

            this.target = target;
    	},

        getEffect: function(x, y) { 
            var effect = new SpellEffect(this.id+1, this.kind);
            effect.setGridPosition(this.target.gridX, this.target.gridY);
            return effect;
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
            this.target = target;
            var orientation = globalGame.player.orientation;
            var trackingId = null;

            if (this.spellType == "single") {
                // maybe apply sparks to the target?
            } else if (this.spellType == "directional") {
                var kind = Types.Entities.BURGER;
                var item = new Items.Burger();
                item.interactable = false;
                
                trackingId = item.id;

                //globalGame.addEntity(effect);
                globalGame.addItem(item, globalGame.player.gridX, globalGame.player.gridY);
                console.log(globalGame.entities[item.id]);
                item.interval = setInterval(function(){
                    item.moveSteps(1, orientation);
                    var entity = globalGame.getEntityAt(item.gridX, item.gridY);
                    if (entity instanceof Mob) {
                       clearInterval(item.interval);
                       clearInterval(item.timeout);
                       globalGame.removeItem(item);
                    }
                }, 80);

                item.timeout = setTimeout(function(){
                    //globalGame.removeEntity(effect);
                    clearInterval(item.interval);
                    globalGame.removeItem(item);
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

        draw: function(context, tilesize, scale) {
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
