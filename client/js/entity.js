define(['lib/underscore.min'], function () {

  var Entity = Class.extend({
    data: {
      name: "unknown",
      x: 0,
      y: 0
    },

    init: function (id, kind) {
      var self = this;

      this.interactable = true;

      this._name = "unknown";
      this._x = 0;
      this._y = 0;

      // Renderer
      this.nameOffsetY = -10;

      this.gridX = 0;
      this.gridY = 0;

      // Position
      this.setGridPosition(0, 0);


      if (id) {
        this.id = id;
      } else {
        this.id = Math.floor(Math.random() * 100000 + 100000);
      }

      this.kind = kind;

      // Renderer
      this.animations = {};

      // Modes
      this.isLoaded = false;

      this.reset();
    },

    reset: function () {
      // Renderer
      this.removed = false;
      this.flipSpriteX = false;
      this.flipSpriteY = false;
      this.currentAnimation = null;
      this.shadowOffsetY = 0;

      // Modes
      this.isHighlighted = false;
      this.visible = true;
      this.isFading = false;
      this.dirty();
    },

    get sprite() {
      return this._sprite;
    },

    set sprite(sprite) {
      this._sprite = sprite;
    },

    get x() {
      return this._x;
    },

    get y() {
      return this._y;
    },

    set x(x) {
      this._x = x;
    },

    set y(y) {
      this._y = y;
    },

    get name() {
      return this._name;
    },

    set name(name) {
      this._name = name;
    },

    setPosition: function (x, y) {
      this.x = x;
      this.y = y;

      this.trigger("PositionChange");
    },

    setGridPosition: function (x, y) {
      this.gridX = x;
      this.gridY = y;

      this.setPosition(x * 16, y * 16);
    },

    moveSteps: function (steps, orientation) {
      var gridX = this.gridX,
        gridY = this.gridY;

      switch (orientation) {
      case Types.Orientations.LEFT:
        gridX -= steps;
        break;
      case Types.Orientations.UP:
        gridY -= steps;
        break;
      case Types.Orientations.RIGHT:
        gridX += steps;
        break;
      case Types.Orientations.DOWN:
        gridY += steps;
        break;
      }

      this.setGridPosition(gridX, gridY);
    },


    setSprite: function (sprite, kindString) {
      if (!sprite) {
        throw "Error: " + this.id + " sprite is null (" + kindString + ")";
      }

      if (this.sprite && this.sprite.name === sprite.name) {
        return;
      }

      this.sprite = sprite;
      this.normalSprite = this.sprite;

      if (Types.isMob(this.kind) || Types.isPlayer(this.kind)) {
        this.hurtSprite = sprite.getHurtSprite();
      }

      _.extend(this.animations, sprite.createAnimations());

      this.isLoaded = true;
      if (this.ready_func) {
        this.ready_func();
      }
    },

    get skin() {
      return this.kind;
    },

    getSprite: function () {
      return this.sprite;
    },

    getSpriteName: function ()  {
      return Types.getKindAsString(this.kind);
    },

    get kindName() {
      return Types.getKindAsString(this.kind);
    },

    getAnimationByName: function (name) {
      var animations = this.animations;
      var animation = null;

      if (name in animations) {
        animation = animations[name];
      } else {
        log.error("No animation called " + name);
      }
      return animation;
    },

    setAnimation: function (name, speed, count, onEndCount) {
      var self = this;

      if (this.isLoaded) {
        if (this.currentAnimation && this.currentAnimation.name === name) {
          return;
        }

        var s = this.sprite,
          a = this.getAnimationByName(name);

        if (a) {
          this.currentAnimation = a;
          if (name.substr(0, 3) === "atk") {
            this.currentAnimation.reset();
          }
          this.currentAnimation.setSpeed(speed);
          this.currentAnimation.setCount(count ? count : 0, onEndCount || function () {
            self.idle();
          });
        }
      } else {
        this.log_error("Not ready for animation");
      }
    },

    hasShadow: function () {
      return false;
    },

    ready: function (f) {
      this.ready_func = f;
    },

    clean: function () {
      this.stopBlinking();
    },

    log_info: function (message) {
      log.info("[" + this.id + "] " + message);
    },

    log_error: function (message) {
      log.error("[" + this.id + "] " + message);
    },

    setHighlight: function (value) {
      if (value === true) {
        this.sprite = this.sprite.silhouetteSprite;
        this.isHighlighted = true;
      } else {
        this.sprite = this.normalSprite;
        this.isHighlighted = false;
      }
    },

    setVisible: function (value) {
      this.visible = value;
    },

    isVisible: function () {
      return this.visible;
    },

    toggleVisibility: function () {
      if (this.visible) {
        this.setVisible(false);
      } else {
        this.setVisible(true);
      }
    },

    isHostile: function (entity) {
      return false;
    },

    distanceTo: function (entity) {
      var distance = Math.sqrt(
        Math.pow(this.gridX - entity.gridX, 2) + Math.pow(this.gridY - entity.gridY, 2)
      );
      // round to 3 digit precision
      return Math.round(distance * Math.pow(10, 3)) / Math.pow(10, 3);
    },

    /**
     *
     */
    getDistanceToEntity: function (entity) {
      var distX = Math.abs(entity.gridX - this.gridX);
      var distY = Math.abs(entity.gridY - this.gridY);

      return (distX > distY) ? distX : distY;
    },

    isCloseTo: function (entity) {
      var dx, dy, d, close = false;
      if (entity) {
        dx = Math.abs(entity.gridX - this.gridX);
        dy = Math.abs(entity.gridY - this.gridY);

        if (dx < 30 && dy < 14) {
          close = true;
        }
      }
      return close;
    },

    /**
     * Returns true if the entity is adjacent to the given one.
     * @returns {Boolean} Whether these two entities are adjacent.
     */
    isAdjacent: function (entity) {
      var adjacent = false;

      if (entity) {
        adjacent = this.getDistanceToEntity(entity) > 1 ? false : true;
      }
      return adjacent;
    },

    /**
     *
     */
    isAdjacentNonDiagonal: function (entity) {
      var result = false;

      if (this.isAdjacent(entity) && !(this.gridX !== entity.gridX && this.gridY !== entity.gridY)) {
        result = true;
      }

      return result;
    },

    isDiagonallyAdjacent: function (entity) {
      return this.isAdjacent(entity) && !this.isAdjacentNonDiagonal(entity);
    },

    forEachAdjacentNonDiagonalPosition: function (callback) {
      callback(this.gridX - 1, this.gridY, Types.Orientations.LEFT);
      callback(this.gridX, this.gridY - 1, Types.Orientations.UP);
      callback(this.gridX + 1, this.gridY, Types.Orientations.RIGHT);
      callback(this.gridX, this.gridY + 1, Types.Orientations.DOWN);

    },

    fadeIn: function (currentTime) {
      this.isFading = true;
      this.startFadingTime = currentTime;
    },

    blink: function (speed, callback) {
      var self = this;

      this.blinking = setInterval(function () {
        self.toggleVisibility();
      }, speed);
    },

    stopBlinking: function () {
      if (this.blinking) {
        clearInterval(this.blinking);
      }
      this.setVisible(true);
    },

    dirty: function () {
      this.isDirty = true;
      this.trigger("dirty");
    }
  });

  return Entity;
});
