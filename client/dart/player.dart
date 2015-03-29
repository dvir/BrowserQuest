library player;

import "dart:async";
import "dart:html";

import "character.dart";
import "entity.dart";
import "game.dart";
import "item.dart";
import "mob.dart";
import "party.dart";
import "position.dart";
import "lib/gametypes.dart";

class Player extends Character {

  int _xp = 0;
  int _maxXP = 0;

  Party party;
  Map<String, String> guild;

  bool isLootMoving = false;

  bool isSwitchingWeapon = true;
  Timer switchingWeaponTimer;
  
  bool isSwitchingArmor = true;
  Timer switchingArmorTimer;

  bool isInvincible = false;
  Timer invincibilityTimer;

  Player(int id, String name, EntityKind kind): super(id, kind) {
    this.name = name;
  }

  EntityKind get weapon => super.weapon == null ? Entities.SWORD1 : super.weapon;
  EntityKind get armor => super.armor == null ? Entities.CLOTHARMOR : super.armor;

  void reset() {
    super.reset();

    this.isLootMoving = false;
    this.isSwitchingWeapon = true;
  }

  bool isHostile(Entity entity) =>
    (entity is Mob)
    || (entity is Player
        && this.id != entity.id
        && (this.guild == null
            || entity.guild == null
            || this.guild['name'] != entity.guild['name'])
        && (this.party == null
            || !this.party.isMember(entity))
       );

  List<List<int>> requestPathfindingTo(Position position) {
    return Game.findPath(this, position);
  }

  String get areaName => "";

  void loot(Item item) {
    window.console.info("Player ${this.id} has looted ${item.id}");
    item.looted(this);
  }

  EntityKind get skin {
    if (this.isDying) {
      return Entities.DEATH;
    }

    if (this.isInvincible) {
      return Entities.FIREFOX;
    }

    return super.skin;
  }

  int get xp => this._xp;
  void set xp(int xp) {
    this._xp = xp;
    this.trigger("XPChange");
  }

  int get maxXP => this._maxXP;
  void set maxXP(int maxXP) {
    this._maxXP = maxXP;
    this.trigger("XPChange");
  }

  void switchWeapon(Item item) {
    if (this.isSwitchingWeapon && this.switchingWeaponTimer != null) {
      this.switchingWeaponTimer.cancel();
    }

    this.isSwitchingWeapon = true;
    int count = 14;
    this.switchingWeaponTimer = new Timer(new Duration(milliseconds: 90), () {
      this.showWeapon = !this.showWeapon;

      count--;
      if (count == 1) {
        this.switchingWeaponTimer.cancel();
        this.showWeapon = true;
        this.isSwitchingWeapon = false;
      }
    });
  }

  void switchArmor(Item item) {
    if (this.isSwitchingArmor && this.switchingArmorTimer != null) {
      this.switchingArmorTimer.cancel();
    }

    this.isSwitchingArmor = true;
    int count = 14;
    this.switchingArmorTimer = new Timer(new Duration(milliseconds: 90), () {
      this.showArmor = !this.showArmor;

      count--;
      if (count == 1) {
        this.switchingArmorTimer.cancel();
        this.showArmor = true;
        this.isSwitchingArmor = false;
      }
    });
  }

  void startInvincibility() {
    if (this.isInvincible) {
      // If the player already has invincibility, just reset its duration.
      if (this.invincibilityTimer != null && this.invincibilityTimer.isActive) {
        this.invincibilityTimer.cancel();
      }
    } else {
      this.isInvincible = true;
    }

    this.invincibilityTimer = new Timer.periodic(new Duration(seconds: 15), (Timer timer) {
      this.stopInvincibility();
      this.idle();
    });
  }

  void stopInvincibility() {
    this.isInvincible = false;

    if (this.invincibilityTimer != null && this.invincibilityTimer.isActive) {
      this.invincibilityTimer.cancel();
    }
  }

  void equip(EntityKind itemKind) {
    if (Types.isArmor(itemKind)) {
      this.armor = itemKind;
    } else if (Types.isWeapon(itemKind)) {
      this.weapon = itemKind;
    }
  }

  void loadFromObject(data) {
    // TODO(data-sync): we need better mechanisms here to verify data integrity.
    // also, it would be better to split this function into two use cases:
    // either creating a new entity and filling it with data, 
    // or just updating an existing one. this will allow us to verify the data
    // per case.

    if (data.containsKey('x') && data.containsKey('y')) {
      // x and y in server are mapped to gridX and gridY on client
      this.gridPosition = new Position(data['x'], data['y']);
    }

    this.name = data['name'];
    this.hp = data['hp'];
    this.maxHP = data['maxHP'];
    this.xp = data['xp'];
    this.maxXP = data['maxXP'];
    this.level = data['level'];
    this.guild = data['guild'];
    if (data.containsKey('weapon')) {
      this.weapon = Entities.get(data['weapon']);
    }
    if (data.containsKey('armor')) {
      this.armor = Entities.get(data['armor']);
    }
  }
}
