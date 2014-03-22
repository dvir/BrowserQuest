library entity;

import "dart:async";
import "dart:html" as html;
import "dart:math";

import "animation.dart";
import "base.dart";
import "rect.dart";
import "sprite.dart";
import "position.dart";
import "../shared/dart/gametypes.dart";

class Entity extends Base {
  int id;
  Entities kind;
  bool interactable = true;
  String name;
  
  int gridX = 0;
  int gridY = 0;

  bool isLoaded = false;
  bool isHighlighted = false;
  bool isVisible = true;
  bool isDirty = false;

  bool isFading = false;
  num fadingAlpha = 1;
  int startFadingTime;

  Timer blinkingTimer;

  Orientation direction;

  // Renderer
  Sprite _sprite;
  Map<String, Animation> animations;
  Animation currentAnimation;
  int nameOffsetY = -10;
  int shadowOffsetY = 0;
  bool isRemoved = false;
  bool flipSpriteX = false; 
  bool flipSpriteY = false; 
  Rect dirtyRect;
  Rect oldDirtyRect;

  Entity(int this.id, Entities this.kind);

  Position get gridPosition => new Position(this.gridX, this.gridY);

  Sprite get sprite {
    if (this.isHighlighted) {
      return this.sprite.silhouetteSprite;
    }

    return this._sprite;
  }

  void set sprite(Sprite sprite) {
    this._sprite = sprite;
  }

  int get x => this.gridX * 16;
  void set x(int x) { 
    this.gridX = (x / 16).floor();
  }

  int get y => this.gridY * 16;
  void set y(int y) {
    this.gridY = (y / 16).floor();
  }

  void reset() {
    // Renderer
    this.isRemoved = false;
    this.flipSpriteX = false;
    this.flipSpriteY = false;
    this.currentAnimation = null;
    this.shadowOffsetY = 0;

    // Modes
    this.isHighlighted = false;
    this.isVisible = true;
    this.isFading = false;
    this.dirty();
  }

  void setGridPosition(int gridX, int gridY) {
    this.gridX = gridX;
    this.gridY = gridY;

    this.trigger("PositionChange");
  }

  void moveSteps(int steps, Orientation orientation) {
    int gridX = this.gridX;
    int gridY = this.gridY;

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

    this.setGridPosition(gridX, gridY);
  }

  void setSprite(Sprite sprite) {
    // don't change to the same sprite
    if (this._sprite != null && this._sprite.name == sprite.name) {
      return;
    }

    this._sprite = sprite;
    this.animations.addAll(sprite.createAnimations());

    this.isLoaded = true;
    this.trigger("Ready");
  }

  Entities get skin => this.kind;

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

  void setHighlight(bool isHighlighted) {
    this.isHighlighted = isHighlighted;
  }

  bool isHostile(Entity entity) => false;

  num distanceTo(Entity entity) => sqrt(pow(this.gridX - entity.gridX, 2) + pow(this.gridY - entity.gridY, 2));

  int getDistanceToEntity(Entity entity) => max((this.gridX - entity.gridX).abs(), (this.gridY - entity.gridY).abs());

  bool isCloseTo(Entity entity) => (this.gridX - entity.gridX).abs() < 30 && (this.gridY - entity.gridY).abs() < 14;

  bool isAdjacent(Entity entity) => this.getDistanceToEntity(entity) > 1 ? false : true;

  bool isAdjacentNonDiagonal(Entity entity) => this.isAdjacent(entity) && !(this.gridX != entity.gridX && this.gridY != entity.gridY);

  bool isDiagonallyAdjacent(Entity entity) => this.isAdjacent(entity) && !this.isAdjacentNonDiagonal(entity);

  void forEachAdjacentNonDiagonalPosition(callback) {
    callback(this.gridX - 1, this.gridY, Orientation.LEFT);
    callback(this.gridX, this.gridY - 1, Orientation.UP);
    callback(this.gridX + 1, this.gridY, Orientation.RIGHT);
    callback(this.gridX, this.gridY + 1, Orientation.DOWN);
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
