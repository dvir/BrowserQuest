define(['character', 'timer'], function (Character, Timer) {

  var Updater = Class.extend({
    init: function (game) {
      this.game = game;
      this.playerAggroTimer = new Timer(1000);
    },

    update: function () {
      this.updateZoning();
      this.updateCharacters();
      this.updatePlayerAggro();
      this.updateTransitions();
      this.updateAnimations();
      this.updateAnimatedTiles();
      this.updateChatBubbles();
      this.updateInfos();
      this.updateKeyboardMovement();
    },

    updateCharacters: function () {
      this.game.forEachEntity(function (entity) {
        var isCharacter = entity instanceof Character;

        if (entity.isLoaded) {
          if (isCharacter) {
            this.updateCharacter(entity);
            this.game.updateCharacter(entity);
          }

          this.updateEntityFading(entity);
        }
      }.bind(this));
    },

    updatePlayerAggro: function () {
      var t = this.game.currentTime,
        player = this.game.player;

      // Check player aggro every 1s when not moving nor attacking
      if (player && !player.isMoving() && !player.isAttacking() && this.playerAggroTimer.isOver(t)) {
        player.checkAggro();
      }
    },

    updateEntityFading: function (entity) {
      if (entity && entity.isFading) {
        var duration = 1000,
          t = this.game.currentTime,
          dt = t - entity.startFadingTime;

        if (dt > duration) {
          this.isFading = false;
          entity.fadingAlpha = 1;
        } else {
          entity.fadingAlpha = dt / duration;
        }
      }
    },

    updateTransitions: function () {
      this.game.forEachEntity(function (entity) {
        if (entity.movement && entity.movement.inProgress) {
          entity.movement.step(this.game.currentTime);
        }
      }.bind(this));

      if (this.game.currentZoning && this.game.currentZoning.inProgress) {
        this.game.currentZoning.step(this.game.currentTime);
      }
    },

    updateZoning: function () {
      var g = this.game,
        c = g.camera,
        z = g.currentZoning,
        s = 3,
        ts = 16,
        speed = 500;

      if (z && z.inProgress === false) {
        var orientation = this.game.zoningOrientation,
          startValue = endValue = offset = 0,
          updateFunc = null,
          endFunc = null;

        if (orientation === Types.Orientations.LEFT || orientation === Types.Orientations.RIGHT) {
          offset = (c.gridW - 2) * ts;
          startValue = (orientation === Types.Orientations.LEFT) ? c.x - ts : c.x + ts;
          endValue = (orientation === Types.Orientations.LEFT) ? c.x - offset : c.x + offset;
          updateFunc = function (x) {
            c.setPosition(x, c.y);
            g.initAnimatedTiles();
            g.renderer.renderStaticCanvases();
          }
          endFunc = function () {
            c.setPosition(z.endValue, c.y);
            g.endZoning();
          }
        } else if (orientation === Types.Orientations.UP || orientation === Types.Orientations.DOWN) {
          offset = (c.gridH - 2) * ts;
          startValue = (orientation === Types.Orientations.UP) ? c.y - ts : c.y + ts;
          endValue = (orientation === Types.Orientations.UP) ? c.y - offset : c.y + offset;
          updateFunc = function (y) {
            c.setPosition(c.x, y);
            g.initAnimatedTiles();
            g.renderer.renderStaticCanvases();
          }
          endFunc = function () {
            c.setPosition(c.x, z.endValue);
            g.endZoning();
          }
        }

        z.start(this.game.currentTime, updateFunc, endFunc, startValue, endValue, speed);
      }
    },

    updateCharacter: function (c) {
      // Estimate of the movement distance for one update
      var tick = Math.round(16 / Math.round((c.moveSpeed / (1000 / this.game.renderer.FPS))));

      if (c.isMoving() && c.movement.inProgress === false) {
        if (c.orientation === Types.Orientations.LEFT) {
          c.movement.start(
            this.game.currentTime,
            function (x) {
              c.x = x;
              c.moved();
            },
            function () {
              c.x = c.movement.endValue;
              c.moved();
              c.nextStep();
            },
            c.x - tick,
            c.x - 16,
            c.moveSpeed
          );
        } else if (c.orientation === Types.Orientations.RIGHT) {
          c.movement.start(
            this.game.currentTime,
            function (x) {
              c.x = x;
              c.moved();
            },
            function () {
              c.x = c.movement.endValue;
              c.moved();
              c.nextStep();
            },
            c.x + tick,
            c.x + 16,
            c.moveSpeed
          );
        } else if (c.orientation === Types.Orientations.UP) {
          c.movement.start(
            this.game.currentTime,
            function (y) {
              c.y = y;
              c.moved();
            },
            function () {
              c.y = c.movement.endValue;
              c.moved();
              c.nextStep();
            },
            c.y - tick,
            c.y - 16,
            c.moveSpeed
          );
        } else if (c.orientation === Types.Orientations.DOWN) {
          c.movement.start(
            this.game.currentTime,
            function (y) {
              c.y = y;
              c.moved();
            },
            function () {
              c.y = c.movement.endValue;
              c.moved();
              c.nextStep();
            },
            c.y + tick,
            c.y + 16,
            c.moveSpeed
          );
        }
      }
    },

    updateAnimations: function () {
      var t = this.game.currentTime;

      this.game.forEachEntity(function (entity) {
        if (entity.currentAnimation && entity.currentAnimation.update(t)) {
          entity.dirty();
        }
      });

      if (this.game.sparksAnimation) {
        this.game.sparksAnimation.update(t);
      }

      if (this.game.targetAnimation) {
        this.game.targetAnimation.update(t);
      }
    },

    updateAnimatedTiles: function () {
      var t = this.game.currentTime;

      this.game.forEachAnimatedTile(function (tile) {
        if (!tile.animate(t)) {
          return;
        }
        
        tile.isDirty = true;
        tile.dirtyRect = this.game.renderer.getTileBoundingRect(tile);

        if (this.game.renderer.mobile || this.game.renderer.tablet) {
          this.game.checkOtherDirtyRects(tile.dirtyRect, tile, tile.x, tile.y);
        }
      }.bind(this));
    },

    updateChatBubbles: function () {
      var t = this.game.currentTime;

      this.game.bubbleManager.update(t);
    },

    updateInfos: function () {
      var t = this.game.currentTime;

      this.game.infoManager.update(t);
    },

    updateKeyboardMovement: function () {
      if (!this.game.player || this.game.player.isMoving()) return;

      this.game.selectedCellVisible = false;

      var game = this.game;
      var player = this.game.player;

      var pos = {
        x: player.gridX,
        y: player.gridY
      };

      if (player.moveUp) {
        pos.y -= 1;
        game.keys(pos, Types.Orientations.UP);
      } else if (player.moveDown) {
        pos.y += 1;
        game.keys(pos, Types.Orientations.DOWN);
      } else if (player.moveRight) {
        pos.x += 1;
        game.keys(pos, Types.Orientations.RIGHT);
      } else if (player.moveLeft) {
        pos.x -= 1;
        game.keys(pos, Types.Orientations.LEFT);
      }
    }
  });

  return Updater;
});
