define(['character',
  'mob',
  'exceptions',
  'inventory',
  'skillbar',
  'chest',
  'npc'
], function (
  Character,
  Mob,
  Exceptions,
  Inventory,
  Skillbar,
  Chest,
  Npc) {

  var Player = Character.extend({
    data: {
      // xp
      xp: 0,
      maxXP: 0,
    },

    init: function (id, name, kind) {
      this._super(id, kind);

      this._xp = 0;
      this._maxXP = 0;

      this.name = name;
      this.party = null;
      this.guild = null;

      this.reset();
    },

    reset: function () {
      this._super();

      // modes
      this.isLootMoving = false;
      this.isSwitchingWeapon = true;
    },

    isHostile: function (entity) {
      return (
             (entity instanceof Mob) 
             || ((entity instanceof Player) 
                 && this.id != entity.id
                 && (!this.guild 
                     || !entity.guild 
                     || this.guild.name != entity.guild.name)
                 && (!this.party
                     || !this.party.isMember(entity))
                )
      );
    },

    requestPathfindingTo: function (x, y) {
      var ignored = [this]; // Always ignore self

      if (this.hasTarget()) {
        ignored.push(this.target);
      }
      return globalGame.findPath(this, x, y, ignored);
    },

    get areaName() {
      return "n/a";
    },

    loot: function (item) {
      log.info('Player ' + this.id + ' has looted ' + item.id);
      item.looted(this);
    },

    /**
     * Returns true if the character is currently walking towards an item in order to loot it.
     */
    isMovingToLoot: function () {
      return this.isLootMoving;
    },

    getSpriteName: function () {
      return this.spriteName;
    },

    get skin() {
      if (this.isDying) {
        return Types.Entities.DEATH;
      }

      if (this.invincible) {
        return Types.Entities.FIREFOX;
      }

      if (!this.armor) {
        return this.kind;
      }

      return this.armor;
    },

    get xp() {
      return this._xp;
    },

    set xp(xp) {
      this._xp = xp;
      this.trigger("XPChange");
    },

    get maxXP() {
      return this._maxXP;
    },

    set maxXP(maxXP) {
      this._maxXP = maxXP;
      this.trigger("XPChange");
    },

    getWeaponName: function () {
      return this.weaponName;
    },

    setWeaponName: function (name) {
      this.weaponName = name;
    },

    hasWeapon: function () {
      return this.weaponName !== null;
    },

    switchWeapon: function (item) {
      var count = 14;
      var value = false;

      var toggle = function () {
        value = !value;
        return value;
      };

      if (this.isSwitchingWeapon) {
        clearInterval(blanking);
      }

      this.switchingWeapon = true;
      var blanking = setInterval(function () {
        if (toggle()) {
          this.weapon = item.kind;
        } else {
          this.weapon = null;
        }

        count -= 1;
        if (count === 1) {
          clearInterval(blanking);
          this.switchingWeapon = false;

          this.changedEquipment();
        }
      }.bind(this), 90);
    },

    switchArmor: function (item) {
      var count = 14;
      var value = false;

      var toggle = function () {
        value = !value;
        return value;
      };

      if (this.isSwitchingArmor) {
        clearInterval(blanking);
      }

      this.isSwitchingArmor = true;
      this.armor = item.kind;
      var blanking = setInterval(function () {
        this.setVisible(toggle());

        count -= 1;
        if (count === 1) {
          clearInterval(blanking);
          this.isSwitchingArmor = false;

          this.changedEquipment();
        }
      }.bind(this), 90);
    },

    changedEquipment: function () {},

    startInvincibility: function () {
      if (this.invincible) {
        // If the player already has invincibility, just reset its duration.
        if (this.invincibleTimeout) {
          clearTimeout(this.invincibleTimeout);
        }
      } else {
        this.invincible = true;
        //globalGame.playerInvincible(true);
      }

      this.invincibleTimeout = setTimeout(function () {
        //this.stopInvincibility();
        this.idle();
      }.bind(this), 15000);
    },

    stopInvincibility: function () {
      //globalGame.playerInvincible(false);
      this.invincible = false;

      if (this.invincibleTimeout) {
        clearTimeout(this.invincibleTimeout);
      }
    },

    equip: function (itemKind) {
      if (Types.isArmor(itemKind)) {
        this.equipArmor(itemKind);
      } else if (Types.isWeapon(itemKind)) {
        this.equipWeapon(itemKind);
      }
    },

    loadFromObject: function (data) {
      // x and y in server are mapped to gridX and gridY on client
      this.setGridPosition(data.x, data.y);
      delete data.x;
      delete data.y;

      $.extend(this, data);
    }
  });

  return Player;
});
