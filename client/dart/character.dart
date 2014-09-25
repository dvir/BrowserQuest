library character;

import "dart:async";
import "dart:html";
import "dart:math";

import "entity.dart";
import "game.dart";
import "sprite.dart";
import "transition.dart";
import "../shared/dart/gametypes.dart";

class Character extends Entity {

  int _hp;
  int _maxHP;
  int _level;

  Entities _weapon;
  Entities _armor;

  // Position and orientation
  int nextGridX = -1;
  int nextGridY = -1;
  Orientation orientation = Orientation.DOWN;

  // Speeds
  int atkSpeed = 50;
  int moveSpeed = 120;
  int walkSpeed = 100;
  int idleSpeed = 450;
  Timer attackCooldown;

  // Pathing
  Transition movement = new Transition();
  var path;
  int step = 0;
  var destination;
  var newDestination;
  var adjacentTiles = {};

  // Combat
  Character _target;
  Character unconfirmedTarget;
  Character previousTarget;
  Map<int, Character> attackers = new Map<int, Entity>();

  // Modes
  bool isDead = false;
  bool isDying = false;
  bool isMovementInterrupted = false;
  bool attackingMode = false;
  bool followingMode = false;
  bool showWeapon = true;
  bool showArmor = true;

  bool isHurting = false;
  Timer hurtingTimer;

  Character(int id, Entities kind): super(id, kind);

  void reset() {
    super.reset();

    // Position and orientation
    this.nextGridX = -1;
    this.nextGridY = -1;
    this.orientation = Orientation.DOWN;

    // Speeds
    this.atkSpeed = 50;
    this.moveSpeed = 120;
    this.walkSpeed = 100;
    this.idleSpeed = 450;
    this.setAttackRate(800);

    // Pathing
    this.movement = new Transition();
    this.path = null;
    this.newDestination = null;
    this.adjacentTiles = {};

    // Combat
    this.target = null;
    this.unconfirmedTarget = null;
    this.attackers = new Map<int, Entity>();

    // Modes
    this.isDead = false;
    this.isDying = false;
    this.attackingMode = false;
    this.followingMode = false;
  }

  void clean() {
    super.clean();

    this.forEachAttacker((Character attacker) {
      attacker.disengage();
      attacker.idle();
    });
  }

  Sprite get sprite {
    if (this.isHurting) {
      return this.sprite.getHurtSprite();
    }

    return super.sprite;
  }

  bool isHostile(Entity entity) => false;

  Character get target => this._target;
  void set target(Character target) {
    this._target = target;
    this.trigger("TargetChange");
    // TODO: remove or uncomment
    // this.trigger("change");
  }

  int get hp => this._hp;
  void set hp(int hp) {
    this._hp = hp;
    this.trigger("HealthChange");
    this.trigger("change");
  }

  int get maxHP => this._maxHP;
  void set maxHP(int maxHP) {
    this._maxHP = maxHP;
    this.trigger("HealthChange");
    this.trigger("change");
  }

  int get level => this._level;
  void set level(int level) {
    this._level = level;
    this.trigger("LevelChange");
    this.trigger("change");
  }

  Entities get armor => this._armor;
  void set armor(Entities armor) {
    this._armor = armor;
    this.trigger("ArmorChange");
    this.trigger("EquipmentChange");
    this.trigger("change");
  }

  Entities get weapon => this._weapon;
  void set weapon(Entities weapon) {
    this._weapon = weapon;
    this.trigger("WeaponChange");
    this.trigger("EquipmentChange");
    this.trigger("change");
  }

  // TODO: remove completely the next four methods.
  // they serve no purpose and armor/weapon should have their own classes to retrieve such
  // information from, and not from some properties data structure.
  void equipArmor(Entities armor) {
    this.armor = armor;
  }
  void equipWeapon(Entities weapon) {
    this.weapon = weapon;
  }
  int getArmorRank() => Types.getArmorRank(this.armor);
  int getWeaponRank() => Types.getWeaponRank(this.weapon);

  bool hasWeapon() => this.weapon != null;

  void setDefaultAnimation() {
    this.idle();
  }

  bool hasShadow() => false;

  void animate(String animationName, int speed, [int count, Function onEndCount]) {
    var oriented = ['atk', 'walk', 'idle'];

    // don't change animation if the character is dying
    if (this.currentAnimation != null && this.currentAnimation.name == "death" && this.isDying) { 
      return;
    }

    this.flipSpriteX = false;
    this.flipSpriteY = false;

    if (oriented.contains(animationName)) {
      animationName += "_" + (this.orientation == Orientation.LEFT ? "right" : Types.getOrientationAsString(this.orientation));
      this.flipSpriteX = (this.orientation == Orientation.LEFT);
    }

    this.setAnimation(animationName, speed, count, onEndCount);
  }

  void turnTo(Orientation orientation) {
    this.orientation = orientation;
    this.idle();
  }

  void idle([Orientation orientation]) {
    if (orientation != null) {
      this.orientation = orientation;
    }

    this.animate("idle", this.idleSpeed);
  }

  void hit([Orientation orientation]) {
    if (orientation != null) {
      this.orientation = orientation;
    }

    this.animate("atk", this.atkSpeed, 1);
  }

  void walk([Orientation orientation]) {
    if (orientation != null) {
      this.orientation = orientation;
    }

    this.animate("walk", this.walkSpeed);
  }

  void moveTo_(int x, int y) {
    this.destination = {
      gridX: x,
      gridY: y
    };
    this.adjacentTiles = {};

    if (this.isMoving()) {
      this.continueTo(x, y);
      return;
    }

    this.followPath(this.requestPathfindingTo(x, y));
  }

  // TODO: give a real type to paths
  requestPathfindingTo(int x, int y) {
    List<Entity> ignored = []; 
    // Always ignore self
    ignored.add(this); 

    // TODO: maybe we should stop ignoring the target??
    //       if we want to move to a location, we just want to get there asap.
    var target = this.hasTarget() ? this.target : this.previousTarget;
    if (target) {
      ignored.add(target);

      // TODO: maybe we should stop ignoring attackers of the target entity?
      //       it might be cool to make the attackers spread around the target entity,
      //       but that is not practical for a lot of attackers and looks pretty stupid
      //       not mentioning moving targets to locations where they are not really present
      
      // also ignore other attackers of the target entity
      target.forEachAttacker((Entity attacker) {
        ignored.add(attacker);
      });
    }

    return Game.findPath(this, x, y, ignored);
  }

  void startPathing(var path) {
  }
  void stopPathing(int x, int y) {
    if (this.isDying) {
      return;
    }

    if (this.hasTarget() && this.isAdjacent(this.target)) {
      this.lookAtTarget();
    }

    this.forEachAttacker((Character attacker) {
      if (!attacker.isAdjacentNonDiagonal(this) && attacker.id != this.id) {
        attacker.follow(this);
      }
    });

    Game.unregisterEntityPosition(this);
    Game.registerEntityPosition(this);
  }

  void followPath(var path) {
    if (path.length <= 1) { // Length of 1 means the player has clicked on himself
      return;
    }

    this.path = path;
    this.step = 0;

    if (this.followingMode) { // following a character
      path.pop();
    }

    this.startPathing(path);
    this.nextStep();
  }

  void continueTo(int x, int y) {
    this.newDestination = {x: x, y: y};
  }

  void updateMovement() {
    if (this.path[this.step][0] < this.path[this.step - 1][0]) {
      this.walk(Orientation.LEFT);
    }
    if (this.path[this.step][0] > this.path[this.step - 1][0]) {
      this.walk(Orientation.RIGHT);
    }
    if (this.path[this.step][1] < this.path[this.step - 1][1]) {
      this.walk(Orientation.UP);
    }
    if (this.path[this.step][1] > this.path[this.step - 1][1]) {
      this.walk(Orientation.DOWN);
    }
  }

  void updatePositionOnGrid() {
    this.setGridPosition(this.path[this.step][0], this.path[this.step][1]);
  }

  void nextStep() {
    bool stop = false;
    int x;
    int y;
    var path;

    if (!this.isMoving()) {
      return;
    }

    this.beforeStep();

    this.updatePositionOnGrid();
    this.checkAggro();

    if (this.isMovementInterrupted) { // if Character.stop() has been called
      stop = true;
      this.isMovementInterrupted = false;
    } else {
      if (this.hasNextStep()) {
        this.nextGridX = this.path[this.step + 1][0];
        this.nextGridY = this.path[this.step + 1][1];
      }

      this.doStep();

      if (this.hasChangedItsPath()) {
        x = this.newDestination.x;
        y = this.newDestination.y;
        path = this.requestPathfindingTo(x, y);

        this.newDestination = null;
        if (path.length < 2) {
          stop = true;
        } else {
          this.followPath(path);
        }
      } else if (this.hasNextStep()) {
        this.step++;
        this.updateMovement();
      } else {
        stop = true;
      }
    }

    if (stop) { // Path is complete or has been interrupted
      this.path = null;
      this.idle();

      this.stopPathing(this.gridX, this.gridY);
    }
  }

  void beforeStep() {
    Game.unregisterEntityPosition(this);
  }

  void doStep() {
    if (this.isDying) {
      return;
    }

    Game.registerEntityDualPosition(this);

    this.forEachAttacker((attacker) {
      if (attacker.isAdjacent(attacker.target)) {
        attacker.lookAtTarget();
      } else {
        attacker.follow(this);
      }
    });
  }

  bool isMoving() => (this.path != null);

  bool hasNextStep() => (this.path.length - 1 > this.step);

  bool hasChangedItsPath() => (this.newDestination != null);

  bool isNear(Character character, num distance) => 
    (this.gridX - character.gridX).abs() <= distance
    && (this.gridY - character.gridY).abs() <= distance;

  checkAggro() {
  }

  aggro(Character character) {
  }

  void lookAtTarget() {
    if (this.hasTarget()) {
      this.turnTo(this.getOrientationTo(this.target));
    }
  }

  void go(int x, int y) {
    if (this.isAttacking()) {
      this.disengage();
    } else if (this.followingMode) {
      this.followingMode = false;
      this.target = null;
    }

    this.moveTo_(x, y);
  }

  void follow(Entity entity) {
    this.followingMode = true;
    this.moveTo_(entity.gridX, entity.gridY);
  }

  void stop() {
    if (this.isMoving()) {
      this.isMovementInterrupted = true;
    }
  }

  /**
   * Makes the character attack another character. Same as Character.follow but with an auto-attacking behavior.
   * @see Character.follow
   */
  void engage(Character character) {
    this.attackingMode = true;
    this.setTarget(character);
    this.follow(character);
  }

  void disengage() {
    this.attackingMode = false;
    this.followingMode = false;
    this.removeTarget();
  }

  bool isAttacking() => this.attackingMode;

  /**
   * Gets the right orientation to face a target character from the current position.
   * Note:
   * In order to work properly, this method should be used in the following
   * situation :
   *    S
   *  S T S
   *    S
   * (where S is self, T is target character)
   *
   * @param {Character} character The character to face.
   * @returns {String} The orientation.
   */
  Orientation getOrientationTo(Character character) {
    if (this.gridX < character.gridX) {
      return Orientation.RIGHT;
    } else if (this.gridX > character.gridX) {
      return Orientation.LEFT;
    } else if (this.gridY > character.gridY) {
      return Orientation.UP;
    }

    return Orientation.DOWN;
  }

  bool isAttackedBy(character) => this.attackers.containsKey(character.id);

  void addAttacker(Character character) {
    this.attackers.putIfAbsent(character.id, () => character);
  }

  void removeAttacker(Character character) {
    this.attackers.remove(character.id);
  }

  /**
   * Loops through all the characters currently attacking this one.
   * @param {Function} callback Function which must accept one character argument.
   */
  void forEachAttacker(void callback(Character character)) {
    this.attackers.forEach((int id, Character character) {
      callback(character);
    });
  }

  void setTarget(Character character) {
    if (this.hasTarget() && this.target == character) { 
      // If it's not already set as the target
      return;
    }

    if (this.hasTarget()) {
      this.removeTarget(); // Cleanly remove the previous one
    }
    this.unconfirmedTarget = null;
    this.target = character;
  }

  void removeTarget() {
    if (!this.hasTarget()) {
      return;
    }

    this.target.removeAttacker(this);
    this.target = null;
  }

  bool hasTarget() => (this.target != null);

  // TODO: figure out if this is needed. applies to the next two methods.
  /**
   * Marks this character as waiting to attack a target.
   * By sending an "attack" message, the server will later confirm (or not)
   * that this character is allowed to acquire this target.
   *
   * @param {Character} character The target character
   */
  void waitToAttack(Character character) {
    this.unconfirmedTarget = character;
  }
  bool isWaitingToAttack(Character character) => (this.unconfirmedTarget == character);

  bool canAttack(int time) => 
      this.canReachTarget() 
      && (this.attackCooldown == null || this.attackCooldown.isActive);

  bool canReachTarget() => (this.hasTarget() && this.isAdjacentNonDiagonal(this.target));

  void die() {
    this.removeTarget();
    this.isDead = true;

    window.console.info("${this.id} is dead");

    this.isDying = true;
    this.setSprite(Game.sprites["death"]);

    this.animate("death", 120, 1, () {
      window.console.info("${this.id} was removed");

      Game.removeEntity(this);
      Game.removeFromRenderingGrid(this, this.gridX, this.gridY);
    });

    this.forEachAttacker((Character attacker) {
      attacker.disengage();
    });

    if (Game.player.target != null && Game.player.target.id == this.id) {
      Game.player.disengage();
    }

    // Upon death, this entity is removed from both grids, allowing the player
    // to click very fast in order to loot the dropped item and not be blocked.
    // The entity is completely removed only after the death animation has ended.
    Game.removeFromEntityGrid(this, this.gridX, this.gridY);
    Game.removeFromPathingGrid(this.gridX, this.gridY);

    if (Game.camera.isVisible(this)) {
      var rng = new Random();
      Game.audioManager.playSound("kill${rng.nextInt(2)+1}");
    }

    Game.updateCursor();
  }

  // TODO: can this turn into .on/.trigger event?
  void moved() {
    this.dirty();

    // Make chat bubbles follow moving entities
    Game.assignBubbleTo(this);
  }

  void hurt() {
    this.stopHurting();
    this.isHurting = true;
    this.hurtingTimer = new Timer(new Duration(milliseconds: 75), this.stopHurting);
  }

  void stopHurting() {
    this.isHurting = false;
    if (this.hurtingTimer != null && this.hurtingTimer.isActive) {
      this.hurtingTimer.cancel();
    }
  }

  // TODO: figure out all the usages of this method. we might be better off
  // with just calculating it off this.atkRate (to be created), 
  // and launching the timer only after an attack so we don't have it running 
  // for each mob all the time.
  void setAttackRate(rate) {
    this.attackCooldown = new Timer(new Duration(milliseconds: rate), () {});
  }
}