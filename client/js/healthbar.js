define(['player'], function(Player){
    var Healthbar = Class.extend({
        init: function($element, character, scale) {
            this.scale = scale;
            this.$element = $element;
            this.$bar = $element.find(".healthbar");
            this.$hp = $element.find(".hitpoints");
            this.healthMaxWidth = this.$bar.width() - (12 * scale);
            this.character = character;

            this.update();
        },

        update: function() {
            if (this.character.hp <= 0 && !(this.character instanceof Player)) {
                this.$element.hide();
            } else {
                this.$element.show();
            }

            var barWidth = Math.round((this.healthMaxWidth / this.character.maxHP) * (this.character.hp > 0 ? this.character.hp : 0));
            this.$hp.css('width', barWidth + "px");
            this.$bar.html(this.character.hp + "/" + this.character.maxHP);
        }
    });

    return Healthbar;
});
