
define(['exceptions', 
        'spell', 
        'item',
        'inventory',
        'inventoryitem',
        'inventoryitemfactory',
        'skillslot'], 
        function(
            Exceptions, 
            Spell, 
            Item,
            Inventory,
            InventoryItem,
            InventoryItemFactory,
            SkillSlot) 
    {

    var Skillbar = Class.extend({ 
        init: function(data) {
            this._size = 12;
            this._skills = [];
            this.reset();
            
            if (data) {
                this.loadFromObject(data);
            }
        },

        key: function(i) {
            if (i < 10) {
                return (i+1) % 10; // [ 1 2 .. 9 0 ] sequence
            }

            switch (i) {
                case 10: 
                    return "-";
                    break;

                case 11:
                    return "=";
                    break;

                default:
                    throw "No such key '"+i+"'";
            }
        },

        reset: function() {
            this._skills = [];
            for (var i = 0; i < this.size; i++) {
                this._skills[i] = null;
            }
        },

        get size () {
            return this._size;
        },

        update: function() {
            for (var i in this._skills) {
                var skillSlot = this._skills[i];
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
                            this.set(i, null);
                        }
                    }
                }
            }
        },

        click: function(key, target) {
            $.each(this._skills, function(idx, skill) {
                if (skill && skill.keyBind == key) {
                    skill.use(target);
                    return;
                }
            });

            // no skill was bounded to the key.
            // execute default
            switch (key) {
                case 187:
                    key = 59;
                    break;
                case 189:
                    key = 58;
                    break;
            }
            key -= 48;
            if (key < 10) {
                if (key == 0) {
                    key = 9;
                } else {
                    key--;
                }
            }
            if (this._skills[key]) {
                this._skills[key].use(target);
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

           this.sync();
        },

        set: function(idx, skill) {
            var skillSlot = null;
            if (skill) {
                skillSlot = new SkillSlot(skill);
            }
            this._skills[idx] = skillSlot; 

            this.sync();
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
            for (var key in self._skills) {
                if (!self._skills[key]) {
                    this.set(key, skill);
                    return;
                }
            }
        },

        remove: function(idx) {
            this._skills[idx] = null;

            this.sync();
        },

        toArray: function() {
            return this._skills;
        },

        loadFromObject: function(data) {
            if (Object.keys(data).length != 2) {
                console.error("Bad data given to Skillbar.loadFromObject");
                console.error(data);
            }

            this._size = data[0];
            if (data[1]) {
                data = data[1];
            }

            this.reset();

            var self = this;
            $.each(data, function(id, slot) {
                var skill;
                if (Types.getType(slot.kind) == "spell") {
                    skill = new Spell(slot.kind);
                } else {
                    skill = InventoryItemFactory.get(slot.id);
                }

                if (skill) {
                    self._skills[slot.slot] = new SkillSlot(skill);
                }
            });
            
            console.log(data);
            console.log(self._skills);

            this.update();
        },

        serialize: function() {
            var data = [];
            for (var key in this._skills) {
                var skillSlot = this._skills[key];
                if (skillSlot) {
                    data.push({slot: key,
                               id: skillSlot.skill.id,
                               kind: skillSlot.skill.kind});
                }
            }

            return data;
        },

        sync: function() {
           globalGame.client.sendSkillbar(this);
        },
    });

    return Skillbar;
});
