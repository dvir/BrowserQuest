library hero;

import "achievements.dart";
import "character.dart";
import "chest.dart";
import "game.dart";
import "inventory.dart";
import "inventoryitem.dart";
import "item.dart";
import "npc.dart";
import "player.dart";
import "skillbar.dart";
import "localstorage.dart";
import "lib/gametypes.dart";
import 'position.dart';

class Hero extends Player {

  Set<Orientation> directions = new Set<Orientation>();

  Inventory inventory;
  Skillbar skillbar;
  LocalStorage storage;

  Hero(int id, String name): super(id, name, Entities.PLAYER) {
    this.skillbar = new Skillbar([]);
    this.inventory = new Inventory([]);
  }

  void die() {
    this.removeTarget();

    this.isDead = true;
    this.isDying = true;

    this.log_info("is dead");

    this.stopBlinking();

    this.animate("death", 120, 1, () {
      this.log_info("was removed");

      this.trigger("Death");
    });

    this.forEachAttacker((Character attacker) {
      attacker.disengage();
      attacker.idle();
    });
  }

  /**
   * This function does pre-step preparations - as for now, just unregister
   * the previous entity position on the grid.
   */
  void beforeStep() {
    Game.unregisterEntityPosition(this);
  }

  void doStep() {
    super.doStep();

    if (Game.isZoningTile(this.gridPosition)) {
      Game.enqueueZoningFrom(this.gridPosition);
    }

    if ((this.gridPosition.x <= 85 && this.gridPosition.y <= 179 && this.gridPosition.y > 178) || (this.gridPosition.x <= 85 && this.gridPosition.y <= 266 && this.gridPosition.y > 265)) {
      Game.tryUnlockingAchievement(Achievement.INTO_THE_WILD);
    }

    if (this.gridPosition.x <= 85 && this.gridPosition.y <= 293 && this.gridPosition.y > 292) {
      Game.tryUnlockingAchievement(Achievement.AT_WORLDS_END);
    }

    if (this.gridPosition.x <= 85 && this.gridPosition.y <= 100 && this.gridPosition.y > 99) {
      Game.tryUnlockingAchievement(Achievement.NO_MANS_LAND);
    }

    if (this.gridPosition.x <= 85 && this.gridPosition.y <= 51 && this.gridPosition.y > 50) {
      Game.tryUnlockingAchievement(Achievement.HOT_SPOT);
    }

    if (this.gridPosition.x <= 27 && this.gridPosition.y <= 123 && this.gridPosition.y > 112) {
      Game.tryUnlockingAchievement(Achievement.TOMB_RAIDER);
    }

    Game.updatePlayerCheckpoint();

    if (!this.isDead) {
      Game.audioManager.updateMusic();
    }
  }

  void startPathing(List<List<int>> path) {
    int i = path.length - 1;
    int x = path[i][0];
    int y = path[i][1];

    if (this.isLootMoving) {
      this.isLootMoving = false;
    } else if (!this.isAttacking()) {
      Game.client.sendMove(new Position(x, y));
    }

    // Target cursor position
    Game.selected = new Position(x, y);
  }
  void stopPathing(Position position) {
    Game.selectedCellVisible = false;

    if (Game.isItemAt(position)) {
      Item item = Game.getItemAt(position);

      // notify the server that the user is trying
      // to loot the item
      Game.client.sendLoot(item);
    }

    if (!this.hasTarget() && Game.map.isDoor(position)) {
      Game.teleport(Game.map.getDoorDestination(position));
    }

    if (this.target is Npc) {
      Game.makeNpcTalk(this.target as Npc);
    } else if (this.target is Chest) {
      Game.client.sendOpen(this.target as Chest);
      Game.audioManager.playSound("chest");
    }

    this.forEachAttacker((Character attacker) {
      if (!attacker.isAdjacentNonDiagonal(this)) {
        attacker.follow(this);
      }
    });

    Game.unregisterEntityPosition(this);
    Game.registerEntityPosition(this);
  }

  String get areaName {
    if (Game.audioManager.getSurroundingMusic(this) != null) {
      return Game.audioManager.getSurroundingMusic(this).name;
    }

    return super.areaName;
  }

  void loadInventory(data) {
    if (this.inventory == null) {
      this.inventory = new Inventory(data);
      return;
    }

    this.inventory.loadFromObject(data);
  }

  void loadSkillbar(data) {
    if (this.skillbar == null) {
      this.skillbar = new Skillbar(data);
      return;
    }

    this.skillbar.loadFromObject(data);
  }

  void lootedArmor(Item item) {
    // make sure that it's better than what we already have, and if so - equip it
    if (this.getArmorRank() >= Types.getArmorRank(item.kind)) {
      return;
    }

    if (item is InventoryItem) {
      item.use();
    }

    // we are optimistically equipping the item before-hand.
    this.switchArmor(item);
  }

  void lootedWeapon(Item item) {
    // make sure that it's better than what we already have, and if so - equip it
    if (this.getWeaponRank() >= Types.getWeaponRank(item.kind)) {
      return;
    }

    if (item is InventoryItem) {
      item.use();
    }

    // we are optimistically equipping the item before-hand.
    this.switchWeapon(item);
  }

  void startInvincibility() {
    if (!this.isInvincible) {
      Game.playerInvincible(true);
    }

    super.startInvincibility();
  }

  void stopInvincibility() {
    Game.playerInvincible(false);

    super.stopInvincibility();
  }

  void equip(EntityKind itemKind) {
    super.equip(itemKind);

    Game.app.initEquipmentIcons();
  }

  void updateStorage() {
    if (this.storage == null) {
      return;
    }

    this.storage.updatePlayer(this);
  }
  
  List<Character> getNearestEnemies() {
    List<Character> nearestEnemies = Game.characters
      .where((Character character) => this != character && this.isHostile(character) && !character.isDead)
      .toList();
    nearestEnemies.sort((Character a, Character b) => this.distanceTo(a) - this.distanceTo(b));
    return nearestEnemies;
  }

  void loadFromObject(data) {
    this.loadInventory(data['inventory']);
    data.remove("inventory");

    // TODO(skillbar): implement
    /*this.loadSkillbar(data.skillbar);*/
    /*data.remove("skillbar");*/

    // we need to load the id as we start with a fake id
    this.id = data['id'];

    super.loadFromObject(data);
  }
}
