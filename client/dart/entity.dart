library entity;

import "dart:async";
import "dart:html" as html;
import "dart:math";

import "animation.dart";
import "base.dart";
import "game.dart";
import "position.dart";
import "rect.dart";
import "sprite.dart";
import "lib/gametypes.dart";

class Entity extends Base {
  int id;
  EntityKind kind;
  bool interactable = true;
  String name;
  
  int x = 0;
  int y = 0;
  Position _gridPosition = const Position(0, 0);
  Orientation orientation = Orientation.DOWN;

  bool isDead = false;
  bool isDying = false;
  bool isLoaded = false;
  bool isHighlighted = false;
  bool isVisible = true;
  bool isDirty = false;
  bool isOnPlateau = false;

  bool isFading = false;
  num fadingAlpha = 1;
  int startFadingTime;

  Timer blinkingTimer;

  // Renderer
  Sprite _sprite;
  Map<String, Animation> animations = {};
  Animation currentAnimation;
  int nameOffsetY = -10;
  int shadowOffsetY = 0;
  bool isRemoved = false;
  bool flipSpriteX = false; 
  bool flipSpriteY = false; 
  Rect dirtyRect;
  Rect oldDirtyRect;

  Entity(int this.id, EntityKind this.kind);

  Position get gridPosition => this._gridPosition;
  void set gridPosition(Position position) {
    if (position == null) {
      throw new Exception("position set to null!");
    }
    this._gridPosition = position;
    this.x = position.x * 16;
    this.y = position.y * 16;
    this.trigger("PositionChange");
  }

  Sprite get sprite {
    if (this._sprite == null) {
      return null;
    }

    return this.isHighlighted ? this._sprite.getSilhouetteSprite() : this._sprite;
  }

  void set sprite(Sprite sprite) {
    this._sprite = sprite;
  }

  void reset() {
    this.orientation = Orientation.DOWN;

    // Renderer
    this.isRemoved = false;
    this.flipSpriteX = false;
    this.flipSpriteY = false;
    this.currentAnimation = null;
    this.shadowOffsetY = 0;

    // Modes
    this.isDead = false;
    this.isDying = false;
    this.isHighlighted = false;
    this.isVisible = true;
    this.isFading = false;
    this.dirty();
  }
  
  void die() {
    html.window.console.info("${this.id} is dead");

    this.isDead = true;
    this.isDying = true;
    this.setSprite(Game.sprites["death"]);

    this.animate("death", 120, 1, () {
      html.window.console.info("${this.id} was removed");

      Game.removeEntity(this);
      Game.removeFromRenderingGrid(this, this.gridPosition);
    });

    // Upon death, this entity is removed from both grids, allowing the player
    // to click very fast in order to loot the dropped item and not be blocked.
    // The entity is completely removed only after the death animation has ended.
    Game.removeFromEntityGrid(this, this.gridPosition);
    Game.removeFromPathingGrid(this.gridPosition);

    Game.updateCursor();
  }

  /**
   * Returns whether we changed to the new animation or not.
   */
  bool animate(String animationName, int speed, [int count = 0, Function onEndCount]) {
    // don't change animation if the character is dying
    if (this.currentAnimation != null 
        && this.currentAnimation.name == "death" 
        && this.isDying) {
      return false;
    }

    this.flipSpriteX = false;
    this.flipSpriteY = false;
    List<String> oriented = ['atk', 'walk', 'idle'];
    if (oriented.contains(animationName)) {
      animationName += "_";
      animationName += 
        this.orientation == Orientation.LEFT 
        ? Types.getOrientationAsString(Orientation.RIGHT)
        : Types.getOrientationAsString(this.orientation);
      this.flipSpriteX = this.orientation == Orientation.LEFT;
    }

    this.setAnimation(animationName, speed, count, onEndCount);
    return true;
  }

  void moveSteps(int steps, Orientation orientation) {
    int gridX = this.gridPosition.x;
    int gridY = this.gridPosition.y;

    switch (orientation) {
      case Orientation.LEFT:
        gridX -= steps;
        break;
      case Orientation.UP:
        gridY -= steps;
        break;
      case Orientation.RIGHT:
        gridX += steps;
        break;
      case Orientation.DOWN:
        gridY += steps;
        break;
    }

    this.gridPosition = new Position(gridX, gridY);
  }

  void setSprite(Sprite sprite) {
    if (sprite == null) {
      throw "cannot setSprite to null for entity ${this.id}";
    }

    // don't change to the same sprite
    if (this._sprite != null && this._sprite.name == sprite.name) {
      return;
    }

    this._sprite = sprite;
    this.animations.addAll(sprite.createAnimations());

    this.isLoaded = true;
    this.trigger("Ready");
  }

  EntityKind get skin => this.kind;

  String getSpriteName() => Types.getKindAsString(this.kind);

  void idle([Orientation orientation]) {}

  void setAnimation(String name, int speed, [int count = 0, Function onEndCount]) {
    if (!this.isLoaded) {
      this.log_error("Not ready for animation");
    }

    // if we are already animating the given animation, stop.
    if (this.currentAnimation != null && this.currentAnimation.name == name) {
      return;
    }

    Animation animation = this.animations[name];
    this.currentAnimation = animation;
    if (name.substring(0, 3) == "atk") {
      this.currentAnimation.reset();
    }

    this.currentAnimation.speed = speed;
    this.currentAnimation.count = count;
    this.currentAnimation.on(
      "EndCount", 
      onEndCount is Function ? onEndCount : () { this.idle(); }, 
      /* overwrite old callbacks */ true
    );
  }

  bool hasShadow() => false;

  void clean() {
    this.stopBlinking();
  }

  void log_debug(String message) {
    html.window.console.debug("[$this.id] $message");
  }

  void log_info(String message) {
    html.window.console.info("[$this.id] $message");
  }

  void log_error(String message) {
    html.window.console.error("[$this.id] $message");
  }

  bool isHostile(Entity entity) => false;

  num distanceTo(Entity entity) => sqrt(pow(this.gridPosition.x - entity.gridPosition.x, 2) + pow(this.gridPosition.y - entity.gridPosition.y, 2));

  int getDistanceToEntity(Entity entity) => max((this.gridPosition.x - entity.gridPosition.x).abs(), (this.gridPosition.y - entity.gridPosition.y).abs());

  bool isCloseTo(Entity entity) => (this.gridPosition.x - entity.gridPosition.x).abs() < 30 && (this.gridPosition.y - entity.gridPosition.y).abs() < 14;

  bool isAdjacent(Entity entity) => this.getDistanceToEntity(entity) > 1 ? false : true;

  bool isAdjacentNonDiagonal(Entity entity) => this.isAdjacent(entity) && !(this.gridPosition.x != entity.gridPosition.x && this.gridPosition.y != entity.gridPosition.y);

  bool isDiagonallyAdjacent(Entity entity) => this.isAdjacent(entity) && !this.isAdjacentNonDiagonal(entity);

  void forEachAdjacentNonDiagonalPosition(callback) {
    callback(this.gridPosition.x - 1, this.gridPosition.y, Orientation.LEFT);
    callback(this.gridPosition.x, this.gridPosition.y - 1, Orientation.UP);
    callback(this.gridPosition.x + 1, this.gridPosition.y, Orientation.RIGHT);
    callback(this.gridPosition.x, this.gridPosition.y + 1, Orientation.DOWN);
  }

  void fadeIn(int currentTime) {
    this.isFading = true;
    this.startFadingTime = currentTime;
  }

  void blink(int speed, Function callback) {
    this.blinkingTimer = new Timer.periodic(
      new Duration(milliseconds: speed),
      (Timer timer) { this.isVisible = !this.isVisible; }
    );
  }

  void stopBlinking() {
    if (this.blinkingTimer != null && this.blinkingTimer.isActive) {
      this.blinkingTimer.cancel();
    }

    this.isVisible = true;
  }

  void dirty() {
    this.isDirty = true;
    this.trigger("Dirty");
  }
}
