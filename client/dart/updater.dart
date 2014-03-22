library updater;

import "dart:async";

import "base.dart";
import "character.dart";
import "entity.dart";
import "game.dart";
import "animatedtile.dart";
import "../shared/dart/gametypes.dart";

class Updater extends Base {

  Updater() {
    // TODO: eh?! we are removing this crap alltogether.
    // should be done on the server.
    new Timer.periodic(new Duration(seconds: 1), (Timer timer) {
      // Check player aggro every 1s when not moving nor attacking
      if (Game.player != null && !Game.player.isMoving() && !Game.player.isAttacking()) {
        Game.player.checkAggro();
      }
    });
  }

  void update() {
    this.updateZoning();
    this.updateCharacters();
    this.updateTransitions();
    this.updateAnimations();
    this.updateAnimatedTiles();
    this.updateChatBubbles();
    this.updateInfos();
    this.updateKeyboardMovement();
  }

  void updateCharacters() {
    Game.forEachEntity((Entity entity) {
      if (!entity.isLoaded) {
        return;
      }

      if (entity is Character) {
        this.updateCharacter(entity);
        Game.updateCharacter(entity);
      }

      this.updateEntityFading(entity);
    });
  }

  void updateEntityFading(Entity entity) {
    if (!entity.isFading) {
      return;
    }

    int duration = 1000;
    int dt = Game.currentTime - entity.startFadingTime;

    if (dt > duration) {
      entity.isFading = false;
      entity.fadingAlpha = 1;
    } else {
      entity.fadingAlpha = dt / duration;
    }
  }

  void updateTransitions() {
    Game.forEachCharacter((Character character) {
      if (character.movement.inProgress) {
        character.movement.step(Game.currentTime);
      }
    });

    if (Game.currentZoning && Game.currentZoning.inProgress) {
      Game.currentZoning.step(Game.currentTime);
    }
  }

  void updateZoning() {
    int s = 3;
    int ts = 16;
    int speed = 500;

    if (!Game.currentZoning || Game.currentZoninginProgress) {
      return;
    }

    Orientation orientation = Game.zoningOrientation;
    int startValue = 0;
    int endValue = 0;
    int offset = 0;
    Function updateFunc;
    Function endFunc;

    if (orientation == Orientation.LEFT || orientation == Orientation.RIGHT) {
      offset = (Game.cameragridW - 2) * ts;
      startValue = (orientation == Orientation.LEFT) ? Game.camerax - ts : Game.camerax + ts;
      endValue = (orientation == Orientation.LEFT) ? Game.camerax - offset : Game.camerax + offset;
      updateFunc = (x) {
        Game.camerasetPosition(x, Game.cameray);
        Game.initAnimatedTiles();
        Game.renderer.renderStaticCanvases();
      };
      endFunc = () {
        Game.camerasetPosition(Game.currentZoningendValue, Game.cameray);
        Game.endZoning();
      };
    } else if (orientation == Orientation.UP || orientation == Orientation.DOWN) {
      offset = (Game.cameragridH - 2) * ts;
      startValue = (orientation == Orientation.UP) ? Game.cameray - ts : Game.cameray + ts;
      endValue = (orientation == Orientation.UP) ? Game.cameray - offset : Game.cameray + offset;
      updateFunc = (y) {
        Game.camerasetPosition(Game.camerax, y);
        Game.initAnimatedTiles();
        Game.renderer.renderStaticCanvases();
      };
      endFunc = () {
        Game.camerasetPosition(Game.camerax, Game.currentZoningendValue);
        Game.endZoning();
      };
    }

    Game.currentZoningstart(Game.currentTime, updateFunc, endFunc, startValue, endValue, speed);
  }

  void updateCharacter(Character c) {
    // Estimate of the movement distance for one update
    num tick = (16 / ((c.moveSpeed / (1000 / Game.renderer.FPS))).round()).round();

    if (c.isMoving() && c.movement.inProgress == false) {
      if (c.orientation == Orientation.LEFT) {
        c.movement.start(
          Game.currentTime,
          (x) {
            c.x = x;
            c.moved();
          },
          () {
            c.x = c.movement.endValue;
            c.moved();
            c.nextStep();
          },
          c.x - tick,
          c.x - 16,
          c.moveSpeed
        );
      } else if (c.orientation == Orientation.RIGHT) {
        c.movement.start(
          Game.currentTime,
          (x) {
            c.x = x;
            c.moved();
          },
          () {
            c.x = c.movement.endValue;
            c.moved();
            c.nextStep();
          },
          c.x + tick,
          c.x + 16,
          c.moveSpeed
        );
      } else if (c.orientation == Orientation.UP) {
        c.movement.start(
          Game.currentTime,
          (y) {
            c.y = y;
            c.moved();
          },
          () {
            c.y = c.movement.endValue;
            c.moved();
            c.nextStep();
          },
          c.y - tick,
          c.y - 16,
          c.moveSpeed
        );
      } else if (c.orientation == Orientation.DOWN) {
        c.movement.start(
          Game.currentTime,
          (y) {
            c.y = y;
            c.moved();
          },
          () {
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
  }

  void updateAnimations() {
    Game.forEachEntity((Entity entity) {
      if (entity.currentAnimation && entity.currentAnimation.update(Game.currentTime)) {
        entity.dirty();
      }
    });

    if (Game.sparksAnimation) {
      Game.sparksAnimation.update(Game.currentTime);
    }

    if (Game.targetAnimation) {
      Game.targetAnimation.update(Game.currentTime);
    }
  }

  void updateAnimatedTiles() {
    Game.forEachAnimatedTile((AnimatedTile tile) {
      tile.update(Game.currentTime);
    });
  }

  void updateChatBubbles() {
    Game.bubbleManager.update(Game.currentTime);
  }

  void updateInfos() {
    Game.infoManager.update(Game.currentTime);
  }

  void updateKeyboardMovement() {
    if (!Game.player || Game.player.isMoving()) {
      return;
    }

    Game.selectedCellVisible = false;

    var pos = {
      "x": Game.player.gridX,
      "y": Game.player.gridY
    };

    if (Game.player.moveUp) {
      pos["y"]--;
      Game.keys(pos, Orientation.UP);
    } else if (Game.player.moveDown) {
      pos["y"]++;
      Game.keys(pos, Orientation.DOWN);
    } else if (Game.player.moveRight) {
      pos["x"]++;
      Game.keys(pos, Orientation.RIGHT);
    } else if (Game.player.moveLeft) {
      pos["x"]--;
      Game.keys(pos, Orientation.LEFT);
    }
  }
}
