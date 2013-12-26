define(['item'], function (Item) {

  var Items = {
    Sword2: Item.extend({
      init: function (id) {
        this._super(id, Types.Entities.SWORD2, "weapon");
        this.lootMessage = "You pick up a steel sword";
        this._name = "Sword";
      },
    }),

    Axe: Item.extend({
      init: function (id) {
        this._super(id, Types.Entities.AXE, "weapon");
        this.lootMessage = "You pick up an axe";
        this._name = "Axe";
      },
    }),

    RedSword: Item.extend({
      init: function (id) {
        this._super(id, Types.Entities.REDSWORD, "weapon");
        this.lootMessage = "You pick up a blazing sword";
        this._name = "Red Sword";
      },
    }),

    BlueSword: Item.extend({
      init: function (id) {
        this._super(id, Types.Entities.BLUESWORD, "weapon");
        this.lootMessage = "You pick up a magic sword";
        this._name = "Blue Sword";
      },
    }),

    GoldenSword: Item.extend({
      init: function (id) {
        this._super(id, Types.Entities.GOLDENSWORD, "weapon");
        this.lootMessage = "You pick up the ultimate sword";
        this._name = "Golden Sword";
      },
    }),

    MorningStar: Item.extend({
      init: function (id) {
        this._super(id, Types.Entities.MORNINGSTAR, "weapon");
        this.lootMessage = "You pick up a morning star";
        this._name = "Morning Star";
      },
    }),

    LeatherArmor: Item.extend({
      init: function (id) {
        this._super(id, Types.Entities.LEATHERARMOR, "armor");
        this.lootMessage = "You equip a leather armor";
        this._name = "Leather Armor";
      },
    }),

    MailArmor: Item.extend({
      init: function (id) {
        this._super(id, Types.Entities.MAILARMOR, "armor");
        this.lootMessage = "You equip a mail armor";
        this._name = "Mail Armor";
      },
    }),

    PlateArmor: Item.extend({
      init: function (id) {
        this._super(id, Types.Entities.PLATEARMOR, "armor");
        this.lootMessage = "You equip a plate armor";
        this._name = "Plate Armor";
      },
    }),

    RedArmor: Item.extend({
      init: function (id) {
        this._super(id, Types.Entities.REDARMOR, "armor");
        this.lootMessage = "You equip a ruby armor";
        this._name = "Red Armor";
      },
    }),

    GoldenArmor: Item.extend({
      init: function (id) {
        this._super(id, Types.Entities.GOLDENARMOR, "armor");
        this.lootMessage = "You equip a golden armor";
        this._name = "Golden Armor";
      },
    }),

    Flask: Item.extend({
      init: function (id) {
        this._super(id, Types.Entities.FLASK, "object");
        this.lootMessage = "You drink a health potion";
        this.isStackable = true;
        this._name = "Potion";
      },
    }),

    Cake: Item.extend({
      init: function (id) {
        this._super(id, Types.Entities.CAKE, "object");
        this.lootMessage = "You eat a cake";
        this._name = "Cake";
      },
    }),

    Burger: Item.extend({
      init: function (id) {
        this._super(id, Types.Entities.BURGER, "object");
        this.lootMessage = "You can haz rat burger";
        this._name = "Burger";
      },
    }),

    FirePotion: Item.extend({
      init: function (id) {
        this._super(id, Types.Entities.FIREPOTION, "object");
        this.lootMessage = "You feel the power of Firefox!";
        this._name = "Fire Potion";
      },

      looted: function (player) {
        player.startInvincibility();
      },
    }),
  };

  return Items;
});
