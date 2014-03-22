library hero;

import "dart:async";
import "dart:html" as html;

import "character.dart";
import "chest.dart";
import "entity.dart";
import "game.dart";
// TODO: re-write and then uncomment
/*import "inventory.dart";*/
import "inventoryitem.dart";
import "item.dart";
import "mob.dart";
import "npc.dart";
import "party.dart";
import "player.dart";
// TODO: re-write and then uncomment
/*import "skillbar.dart";*/
import "localstorage.dart";
import "../shared/dart/gametypes.dart";
import 'position.dart';

class Hero extends Player {

  // TODO: uncomment after re-writing them
  /*Inventory inventory;*/
  /*Skillbar skillbar;*/
  LocalStorage storage;

  Hero(int id, String name): super(id, name, Entities.PLAYER) {
    this.on("EquipmentChange", () {
      Game.storage.savePlayer(Game.renderer.getPlayerImage(), this);
      Game.playerChangedEquipment();
    });
  }

  void die() {
    this.removeTarget();
    this.isDead = true;

    this.log_info("is dead");

    this.isDying = true;

    this.stopBlinking();
    this.setSprite(Game.sprites["death"]);

    this.animate("death", 120, 1, () {
      this.log_info("was removed");

      new Timer(new Duration(seconds: 1), () {
        // TODO: move this crap into a Game class helper function
        Game.removeEntity(this);
        Game.removeFromRenderingGrid(this, this.gridX, this.gridY);

        Game.audioManager.fadeOutCurrentMusic();
        Game.audioManager.playSound("death");

        Game.entities = {};
        Game.deathpositions = {};
        Game.currentCursor = null;
        Game.zoningQueue = [];
        Game.previousClickPosition = null;

        Game.initPathingGrid();
        Game.initEntityGrid();
        Game.initRenderingGrid();
        Game.initItemGrid();

        Game.selected = new Position(0, 0);
        Game.selectedCellVisible = false;
        Game.targetColor = "rgba(255, 255, 255, 0.5)";
        Game.targetCellVisible = true;
        Game.hoveringTarget = null;
        Game.hoveringPlayer = null;
        Game.hoveringMob = null;
        Game.hoveringNpc = null;
        Game.hoveringItem = null;
        Game.hoveringChest = null;
        Game.hoveringPlateauTile = false;
        Game.hoveringCollidingTile = false;

        Game.playerDeath();
      });
    });

    this.forEachAttacker((Character attacker) {
      attacker.disengage();
      attacker.idle();
    });
  }

  // TODO: WHAT?! this is highly inefficient. improve this crap.
  //       Also, this should be done on the server side.
  void checkAggro() {
    Game.forEachMob((Mob mob) {
      if (mob.isAggressive 
          && !mob.isAttacking() 
          && this.isNear(mob, mob.aggroRange)
      ) {
        this.aggro(mob);
      }
    });
  }

  // TODO: this should be all in the server side. the client shouldn't be
  //       the one telling the server who aggroed who.
  void aggro(Character character) {
    if (!character.isWaitingToAttack(this) && !this.isAttackedBy(character)) {
      this.log_info("Aggroed by ${character.id} at (${this.gridX},${this.gridY})");
      Game.client.sendAggro(character);
      character.waitToAttack(this);
    }
  }

  /**
   * This function does pre-step preparations - as for now, just unregister
   * the previous entity position on the grid.
   */
  void beforeStep() {
    // TODO: entities shouldn't block each other anymore, so this could be removed.
    var blockingEntity = Game.getEntityAt(this.nextGridX, this.nextGridY);
    if (blockingEntity && blockingEntity.id != this.id) {
      this.log_debug("Blocked by ${blockingEntity.id}");
    }

    Game.unregisterEntityPosition(this);
  }

  void doStep() {
    // TODO: probably not needed.
    /*if (this.hasNextStep()) {*/
      /*Game.registerEntityDualPosition(this);*/
    /*}*/
    super.doStep();

    if (Game.isZoningTile(this.gridX, this.gridY)) {
      Game.enqueueZoningFrom(this.gridX, this.gridY);
    }

    if ((this.gridX <= 85 && this.gridY <= 179 && this.gridY > 178) || (this.gridX <= 85 && this.gridY <= 266 && this.gridY > 265)) {
      Game.tryUnlockingAchievement("INTO_THE_WILD");
    }

    if (this.gridX <= 85 && this.gridY <= 293 && this.gridY > 292) {
      Game.tryUnlockingAchievement("AT_WORLDS_END");
    }

    if (this.gridX <= 85 && this.gridY <= 100 && this.gridY > 99) {
      Game.tryUnlockingAchievement("NO_MANS_LAND");
    }

    if (this.gridX <= 85 && this.gridY <= 51 && this.gridY > 50) {
      Game.tryUnlockingAchievement("HOT_SPOT");
    }

    if (this.gridX <= 27 && this.gridY <= 123 && this.gridY > 112) {
      Game.tryUnlockingAchievement("TOMB_RAIDER");
    }

    Game.updatePlayerCheckpoint();

    if (!this.isDead) {
      Game.audioManager.updateMusic();
    }
  }

  void startPathing(var path) {
    int i = path.length - 1;
    int x = path[i][0];
    int y = path[i][1];

    if (this.isLootMoving) {
      this.isLootMoving = false;
    } else if (!this.isAttacking()) {
      Game.client.sendMove(x, y);
    }

    // Target cursor position
    Game.selected = new Position(x, y);

    if (Game.renderer.mobile || Game.renderer.tablet) {
      Game.drawTarget = true;
      Game.clearTarget = true;
      Game.renderer.targetRect = Game.renderer.getTargetBoundingRect();
      Game.checkOtherDirtyRects(Game.renderer.targetRect, null, Game.selected.x, Game.selected.y);
    }
  }
  void stopPathing(int x, int y) {
    Game.selectedCellVisible = false;

    if (Game.isItemAt(x, y)) {
      Item item = Game.getItemAt(x, y);

      // notify the server that the user is trying
      // to loot the item
      Game.client.sendLoot(item);
    }

    if (!this.hasTarget() && Game.map.isDoor(x, y)) {
      Game.teleport(Game.map.getDoorDestination(x, y));
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

  // TODO: uncomment after re-writing them
  /*void loadInventory(data) {*/
    /*if (this.inventory == null) {*/
      /*this.inventory = new Inventory(data);*/
      /*return;*/
    /*} */

    /*this.inventory.loadFromObject(data);*/
  /*}*/

  /*void loadSkillbar(data) {*/
    /*if (this.skillbar == null) {*/
      /*this.skillbar = new Skillbar(data);*/
      /*return;*/
    /*}*/

    /*this.skillbar.loadFromObject(data);*/
  /*}*/

  void lootedArmor(Item item) {
    // make sure that it's better than what we already have, and if so - equip it
    if (this.getArmorRank() >= Types.getArmorRank(item.kind)) {
      return;
    }

    item.use();

    // we are optimistically equipping the item before-hand.
    this.switchArmor(item);
  }

  void lootedWeapon(Item item) {
    // make sure that it's better than what we already have, and if so - equip it
    if (this.getWeaponRank() >= Types.getWeaponRank(item.kind)) {
      return;
    }

    item.use();

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

  void equip(Entities itemKind) {
    super.equip(itemKind);

    Game.app.initEquipmentIcons();
  }

  void updateStorage() {
    if (this.storage == null) {
      return;
    }

    this.storage.updatePlayer(this);
  }

  void loadFromObject(data) {
    /*this.loadInventory(data.inventory);*/
    /*data.remove("inventory");*/

    /*this.loadSkillbar(data.skillbar);*/
    /*data.remove("skillbar");*/

    super.loadFromObject(data);
  }
}
