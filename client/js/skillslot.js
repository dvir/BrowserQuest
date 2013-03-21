
define(function() {
    
    var SkillSlot = Class.extend({
        init: function(keyBind, skill) {
            this.keyBind = keyBind;
            this.skill = skill;
            this.$htmlElement = null;
        }, 

        use: function(target) {
            this.skill.use(target);

            if (this.$htmlElement) {
                var $skillElement = this.$htmlElement.find("div");
                $skillElement.fadeOut(500, function() {
                    $skillElement.fadeIn(500);
                });
            }
        }
    });
    return SkillSlot;
});
