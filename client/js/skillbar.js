
define(['exceptions', 
        'spell', 
        'item',
        'inventory',
        'inventoryitem',
        'skillslot'], 
        function(
            Exceptions, 
            Spell, 
            Item,
            Inventory,
            InventoryItem,
            SkillSlot) 
    {
    var Skillbar = Class.extend({ 
        init: function(data) {
            var self = this;

            self._size = 10;
            self._skills = [];
            for (var i = 0; i < self.size; i++) {
                self._skills[i] = null;
            }
            
            if (data) {
                self.loadFromObject(data);
            }
        },

        get size () {
            return this._size;
        },

        update: function() {
            var self = this;

            for (var i in self._skills) {
                var skillSlot = self._skills[i];
                if (skillSlot) {
                    var skill = skillSlot.skill;
                    if (skill instanceof InventoryItem) {
                        // make sure it's still in the inventory.
                        var item = null;
                        $.each(globalInventoryItems, function(id, invItem) {
                            if (id == skill.id) {
                                item = invItem;
                                return false;
                            }
                        });

                        if (!item || item.isDeleted) {
                            // it is not in the inventory anymore!
                            // remove it from the skillbar
                            self._skills[i] = null;
                        }
                    }
                }
            }
        },

        click: function(key, target) {
            var self = this;
            $.each(self._skills, function(idx, skill) {
                if (skill && skill.keyBind == key) {
                    skill.use(target);
                    return;
                }
            });

            // no skill was bounded to the key.
            // execute default
            if (self._skills[key-48]) {
                self._skills[key-48].use(target);
            }
        },

        swap: function(first, second) {
           var temp = this._skills[first];
           this._skills[first] = this._skills[second];
           this._skills[second] = temp;

           if (this._skills[first]) {
                this._skills[first].slot = first;
           }
           if (this._skills[second]) {
                this._skills[second].slot = second;
           }
        },

        set: function(idx, skill) {
            this._skills[idx] = new SkillSlot(skill);
        },

        add: function(skillKind) {
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
                    self._skills[i] = new SkillSlot(skill);
                    return;
                }
            }
        },

        remove: function(idx) {
            this._skills[idx] = null;
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
            for (var i = 0; i < self.size; i++) {
                self._skills[i] = null;
            }
            var idx = 0;
            $.each(data, function(id, slot) {
                var skill;
                if (Types.getType(slot.kind) == "spell") {
                    skill = new Spell(slot.kind);
                } else if (Types.getType(slot.kind) == "object") {
                    skill = new Item(slot.kind);
                }
                self._skills[skill.barSlot] = new SkillSlot(skill);
            });
        }
    });

    return Skillbar;
});
