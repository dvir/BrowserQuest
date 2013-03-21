
define(['exceptions', 
        'spell', 
        'item', 
        'skillslot'], 
        function(
            Exceptions, 
            Spell, 
            Item, 
            SkillSlot) 
    {
    var Skillbar = Class.extend({ 
        init: function(data) {
            var self = this;

            this._size = 10;
            this._skills = [];
            
            if (data) {
                this.loadFromObject(data);
            }
        },

        get size () {
            return this._size;
        },

        click: function(key, target) {
            var self = this;
            $.each(self._skills, function(idx, skill) {
                if (skill.keyBind == key) {
                    skill.use(target);
                }
            });
        },

        add: function(keyBind, skillKind) {
            var skill;
            if (Types.getType(skillKind) == "spell") {
                skill = new Spell(skillKind);
            } else if (Types.getType(skillKind) == "object") {
                skill = new Item(skillKind);
            }

            // find the first available slot and place
            // the skill in it
            var self = this;
            for (var i = 0; i < self.size; i++) {
                if (!self._skills[i]) {
                    self._skills[i] = new SkillSlot(keyBind, skill);
                    return;
                }
            }
        },

        remove: function(idx) {
            delete self._skills[idx];
        },

        toArray: function() {
            return this._skills;
        },

        loadFromObject: function(data) {
            if ($.isEmptyObject(data)) {
                return;
            }

            var self = this;

            self._skills = [];
            var idx = 0;
            $.each(data, function(id, slot) {
                var skill;
                if (Types.getType(slot.kind) == "spell") {
                    skill = new Spell(slot.kind);
                } else if (Types.getType(slot.kind) == "object") {
                    skill = new Item(slot.kind);
                }
                self._skills[idx++] = new SkillSlot(idx+48, skill);
            });
        }
    });

    return Skillbar;
});
