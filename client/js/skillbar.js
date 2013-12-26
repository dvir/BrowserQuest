define(['exceptions',
    'spell',
    'item',
    'inventory',
    'inventoryitem',
    'inventoryitemfactory',
    'spells',
    'skillslot'
  ],
  function (
    Exceptions,
    Spell,
    Item,
    Inventory,
    InventoryItem,
    InventoryItemFactory,
    Spells,
    SkillSlot) {

    var Skillbar = Class.extend({
      init: function (data) {
        this._size = 12;
        this._skills = [];
        this.reset();

        this.keyMap = [49, 50, 51, 52, 53, 54, 81, 69, 90, 88, 67, 86];
        //  1,  2,  3,  4,  5,  6,  q,  e,  z,  x,  c,  v
        this.actualKeyMap = ["1", "2", "3", "4", "5", "6", "Q", "E", "Z", "X", "C", "V"];

        if (data) {
          this.loadFromObject(data);
        }
      },

      key: function (i) {
        return this.keyMap[i];
      },

      actualKey: function (i) {
        return this.actualKeyMap[i];
      },

      keySlot: function (key) {
        for (var k in this.keyMap) {
          if (this.keyMap[k] == key) {
            return k;
          }
        }
      },

      reset: function () {
        this._skills = [];
        for (var i = 0; i < this.size; i++) {
          this._skills[i] = null;
        }
      },

      get size() {
        return this._size;
      },

      update: function () {
        for (var i in this._skills) {
          var skillSlot = this._skills[i];
          if (skillSlot) {
            var skill = skillSlot.skill;
            if (skill instanceof InventoryItem) {
              // make sure it's still in the inventory.
              var item = null;
              $.each(globalInventoryItems, function (id, invItem) {
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

      click: function (key, target) {
        if (!target) {
          target = this.player;
        }
        if (this._skills[this.keySlot(key)]) {
          this._skills[this.keySlot(key)].use(target);
        }
      },

      swap: function (first, second) {
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

      set: function (idx, skill) {
        var skillSlot = null;
        if (skill) {
          skillSlot = new SkillSlot(skill);
        }
        this._skills[idx] = skillSlot;

        this.sync();
      },

      add: function (skillKind) {
        var skill;
        if (Types.getType(skillKind) == "spell") {
          skill = Spells.getSpell(skillKind);
        } else if (Types.getType(skillKind) == "object") {
          skill = new Item(skillKind);
        }

        // find the first available slot and place
        // the skill in it
        for (var key in this._skills) {
          if (!this._skills[key]) {
            this.set(key, skill);
            return;
          }
        }
      },

      remove: function (idx) {
        this._skills[idx] = null;

        this.sync();
      },

      toArray: function () {
        return this._skills;
      },

      loadFromObject: function (data) {
        if (Object.keys(data).length != 2) {
          console.error("Bad data given to Skillbar.loadFromObject");
          console.error(data);
        }

        this._size = data[0];
        if (data[1]) {
          data = data[1];
        }

        this.reset();

        $.each(data, function (id, slot) {
          var skill;
          if (Types.getType(slot.kind) == "spell") {
            skill = Spells.getSpell(slot.kind);
          } else {
            skill = InventoryItemFactory.get(slot.id);
          }

          if (skill) {
            this._skills[slot.slot] = new SkillSlot(skill);
          }
        }.bind(this));

        this.update();
      },

      serialize: function () {
        var data = [];
        for (var key in this._skills) {
          var skillSlot = this._skills[key];
          if (skillSlot) {
            data.push({
              slot: key,
              id: skillSlot.skill.id,
              kind: skillSlot.skill.kind
            });
          }
        }

        return data;
      },

      sync: function () {
        globalGame.client.sendSkillbar(this);
      },
    });

    return Skillbar;
  });
