define(['character',
  'player',
  'mob',
  'exceptions',
  'inventory',
  'skillbar',
  'chest',
  'npc'
], function (
  Character,
  Player,
  Mob,
  Exceptions,
  Inventory,
  Skillbar,
  Chest,
  Npc) {

  var Hero = Player.extend({
    init: function (id, name) {
      this._super(id, name, Types.Entities.PLAYER);

      // storage
      this.storage = null;

      this.inventory = new Inventory();
      this.skillbar = new Skillbar();
    },

    isHostile: function (entity) {
      return (
             (entity instanceof Mob) 
             || ((entity instanceof Player) 
                 && this.id != entity.id
                 && (!this.guild 
                     || !entity.guild 
                     || this.guild.name != entity.guild.name)
                )
      );
    },

    die: function () {
      this.removeTarget();
      this.isDead = true;

      log.info(this.id + " is dead");

      this.isDying = true;

      this.stopBlinking();
      this.setSprite(globalSprites["death"]);

      this.animate("death", 120, 1, function () {
        log.info(this.id + " was removed");

        setTimeout(function () {
          globalGame.removeEntity(this);
          globalGame.removeFromRenderingGrid(this, this.gridX, this.gridY);

          globalGame.audioManager.fadeOutCurrentMusic();
          globalGame.audioManager.playSound("death");

          globalGame.entities = {};
          globalGame.deathpositions = {};
          globalGame.currentCursor = null;
          globalGame.zoningQueue = [];
          globalGame.previousClickPosition = {};

          globalGame.initPathingGrid();
          globalGame.initEntityGrid();
          globalGame.initRenderingGrid();
          globalGame.initItemGrid();

          globalGame.selectedX = 0;
          globalGame.selectedY = 0;
          globalGame.selectedCellVisible = false;
          globalGame.targetColor = "rgba(255, 255, 255, 0.5)";
          globalGame.targetCellVisible = true;
          globalGame.hoveringTarget = false;
          globalGame.hoveringPlayer = false;
          globalGame.hoveringMob = false;
          globalGame.hoveringItem = false;
          globalGame.hoveringCollidingTile = false;

          globalGame.playerDeath();
        }.bind(this), 1000);
      }.bind(this));

      this.forEachAttacker(function (attacker) {
        attacker.disengage();
        attacker.idle();
      });
    },

    checkAggro: function () {
      globalGame.forEachMob(function (mob) {
        if (mob.isAggressive && !mob.isAttacking() && this.isNear(mob, mob.aggroRange)) {
          this.aggro(mob);
        }
      }.bind(this));
    },

    aggro: function (character) {
      if (!character.isWaitingToAttack(this) && !this.isAttackedBy(character)) {
        this.log_info("Aggroed by " + character.id + " at (" + this.gridX + ", " + this.gridY + ")");
        globalGame.client.sendAggro(character);
        character.waitToAttack(this);
      }
    },

    beforeStep: function () {
      var blockingEntity = globalGame.getEntityAt(this.nextGridX, this.nextGridY);
      if (blockingEntity && blockingEntity.id !== this.id) {
        //log.debug("Blocked by " + blockingEntity.id);
      }

      globalGame.unregisterEntityPosition(this);
    },

    doStep: function () {
      if (this.hasNextStep()) {
        globalGame.registerEntityDualPosition(this);
      }

      if (globalGame.isZoningTile(this.gridX, this.gridY)) {
        globalGame.enqueueZoningFrom(this.gridX, this.gridY);
      }

      this.forEachAttacker(function (attacker) {
        if (attacker.isAdjacent(attacker.target)) {
          attacker.lookAtTarget();
        } else {
          attacker.follow(this);
        }
      }.bind(this));

      if ((this.gridX <= 85 && this.gridY <= 179 && this.gridY > 178) ||  (this.gridX <= 85 && this.gridY <= 266 && this.gridY > 265)) {
        globalGame.tryUnlockingAchievement("INTO_THE_WILD");
      }

      if (this.gridX <= 85 && this.gridY <= 293 && this.gridY > 292) {
        globalGame.tryUnlockingAchievement("AT_WORLDS_END");
      }

      if (this.gridX <= 85 && this.gridY <= 100 && this.gridY > 99) {
        globalGame.tryUnlockingAchievement("NO_MANS_LAND");
      }

      if (this.gridX <= 85 && this.gridY <= 51 && this.gridY > 50) {
        globalGame.tryUnlockingAchievement("HOT_SPOT");
      }

      if (this.gridX <= 27 && this.gridY <= 123 && this.gridY > 112) {
        globalGame.tryUnlockingAchievement("TOMB_RAIDER");
      }

      globalGame.updatePlayerCheckpoint();

      if (!this.isDead) {
        globalGame.audioManager.updateMusic();
      }
    },

    startPathing: function (path) {
      var i = path.length - 1,
        x = path[i][0],
        y = path[i][1];

      if (this.isMovingToLoot()) {
        this.isLootMoving = false;
      } else if (!this.isAttacking()) {
        globalGame.client.sendMove(x, y);
      }

      // Target cursor position
      globalGame.selectedX = x;
      globalGame.selectedY = y;

      if (globalGame.renderer.mobile || globalGame.renderer.tablet) {
        globalGame.drawTarget = true;
        globalGame.clearTarget = true;
        globalGame.renderer.targetRect = globalGame.renderer.getTargetBoundingRect();
        globalGame.checkOtherDirtyRects(globalGame.renderer.targetRect, null, globalGame.selectedX, globalGame.selectedY);
      }
    },
    stopPathing: function (x, y) {
      globalGame.selectedCellVisible = false;

      if (globalGame.isItemAt(x, y)) {
        var item = globalGame.getItemAt(x, y);

        // notify the server that the user is trying
        // to loot the item
        globalGame.client.sendLoot(item);
      }

      if (!this.hasTarget() && globalGame.map.isDoor(x, y)) {
        var dest = globalGame.map.getDoorDestination(x, y);
        globalGame.teleport(dest);
      }

      if (this.target instanceof Npc) {
        globalGame.makeNpcTalk(this.target);
      } else if (this.target instanceof Chest) {
        globalGame.client.sendOpen(this.target);
        globalGame.audioManager.playSound("chest");
      }

      this.forEachAttacker(function (attacker) {
        if (!attacker.isAdjacentNonDiagonal(this)) {
          attacker.follow(this);
        }
      }.bind(this));

      globalGame.unregisterEntityPosition(this);
      globalGame.registerEntityPosition(this);
    },

    get areaName() {
      if (globalGame.audioManager.getSurroundingMusic(this)) {
        return globalGame.audioManager.getSurroundingMusic(this).name;
      }
    },

    loadInventory: function (data) {
      if (this.inventory) {
        this.inventory.loadFromObject(data);
      } else {
        this.inventory = new Inventory(data);
      }
    },

    loadSkillbar: function (data) {
      if (this.skillbar) {
        this.skillbar.loadFromObject(data);
      } else {
        this.skillbar = new Skillbar(data);
      }
    },

    lootedArmor: function (item) {
      // make sure that it's better than what we already have, and if so - equip it
      if (Types.getArmorRank(item.kind) > Types.getArmorRank(this.armor)) {
        item.use();

        // we are optimistically equipping the item before-hand.
        this.switchArmor(item);
      }
    },

    lootedWeapon: function (item) {
      // make sure that it's better than what we already have, and if so - equip it
      if (Types.getWeaponRank(item.kind) > Types.getWeaponRank(this.weapon)) {
        item.use();

        // we are optimistically equipping the item before-hand.
        this.switchWeapon(item);
      }
    },

    changedEquipment: function () {
      globalGame.storage.savePlayer(globalGame.renderer.getPlayerImage(),
        this);
      globalGame.playerChangedEquipment();
    },

    startInvincibility: function () {
      if (this.invincible) {
        // If the player already has invincibility, just reset its duration.
        if (this.invincibleTimeout) {
          clearTimeout(this.invincibleTimeout);
        }
      } else {
        this.invincible = true;
        globalGame.playerInvincible(true);
      }

      this.invincibleTimeout = setTimeout(function () {
        this.stopInvincibility();
        this.idle();
      }.bind(this), 15000);
    },

    stopInvincibility: function () {
      globalGame.playerInvincible(false);
      this.invincible = false;

      if (this.invincibleTimeout) {
        clearTimeout(this.invincibleTimeout);
      }
    },

    equip: function (itemKind) {
      this._super(itemKind);
      globalGame.app.initEquipmentIcons();
    },

    setStorage: function (storage) {
      this.storage = storage;
    },

    loadFromStorage: function (callback) {
      return;

      if (this.storage && this.storage.hasAlreadyPlayed()) {
        this.armor = this.storage.data.player.armor;
        this.weapon = this.storage.data.player.weapon;
      }

      log.debug("Loaded from storage");

      if (callback) {
        callback();
      }
    },

    updateStorage: function (callback) {
      return;

      if (this.storage) {
        this.storage.data.player.name = this.name;
        this.storage.data.player.armor = this.armor;
        this.storage.data.player.weapon = this.weapon;
      }

      log.debug("Updated storage");

      if (callback) {
        callback();
      }
    },

    loadFromObject: function (data) {
      // x and y in server are mapped to gridX and gridY on client
      this.setGridPosition(data.x, data.y);
      delete data.x;
      delete data.y;

      // set inventory data
      this.loadInventory(data.inventory);
      delete data.inventory;

      // set skillbar data
      this.loadSkillbar(data.skillbar);
      delete data.skillbar;

      $.extend(this, data);
    }
  });

  return Hero;
});
