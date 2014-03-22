library player;

import "dart:async";
import "dart:html";

import "character.dart";
import "chest.dart";
import "entity.dart";
import "game.dart";
import "item.dart";
import "mob.dart";
import "npc.dart";
import "party.dart";
import "../shared/dart/gametypes.dart";

class Player extends Character {

  int _xp = 0;
  int _maxXP = 0;

  String name;
  Party party;
  var guild;

  bool isLootMoving = false;

  bool isSwitchingWeapon = true;
  Timer switchingWeaponTimer;
  
  bool isSwitchingArmor = true;
  Timer switchingArmorTimer;

  bool isInvincible = false;
  Timer invincibilityTimer;

  Player(int id, String this.name, Entities kind): super(id, kind);

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
            || !entity.guild
            || this.guild.name != entity.guild.name)
        && (this.party == null
            || !this.party.isMember(entity))
       );

  // TODO: give a real type to paths
  requestPathfindingTo(int x, int y) {
    List<Entity> ignored = []; // Always ignore self

    // TODO: maybe we should stop ignoring the target??
    //       if we want to move to a location, we just want to get there asap.
    if (this.hasTarget()) {
      ignored.add(this.target);
    }
    return Game.findPath(this, x, y, ignored);
  }

  String get areaName => "n/a";

  void loot(Item item) {
    window.console.info("Player ${this.id} has looted ${item.id}");
    item.looted(this);
  }

  String getSpriteName() => this.sprite.name;

  Entities get skin {
    if (this.isDying) {
      return Entities.DEATH;
    }

    if (this.isInvincible) {
      return Entities.FIREFOX;
    }

    if (this.armor != null) {
      return this.kind;
    }

    return this.armor;
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
    var count = 14;
    this.switchingWeaponTimer = new Timer(new Duration(milliseconds: 90), () {
      this.showWeapon = !this.showWeapon;

      count -= 1;
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
    var count = 14;
    this.switchingArmorTimer = new Timer(new Duration(milliseconds: 90), () {
      this.showArmor = !this.showArmor;

      count -= 1;
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

  void equip(Entities itemKind) {
    if (Types.isArmor(itemKind)) {
      this.equipArmor(itemKind);
    } else if (Types.isWeapon(itemKind)) {
      this.equipWeapon(itemKind);
    }
  }

  void loadFromObject(data) {
    // x and y in server are mapped to gridX and gridY on client
    this.setGridPosition(data.x, data.y);

    this.name = data.name;
    this.hp = data.hp;
    this.maxHP = data.maxHP;
    this.xp = data.xp;
    this.maxXP = data.maxXP;
    this.level = data.level;
    this.guild = data.guild;
    this.weapon = data.weapon;
    this.armor = data.armor;
  }
}
