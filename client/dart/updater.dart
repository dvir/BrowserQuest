library updater;

import "dart:async";

import "animatedtile.dart";
import "base.dart";
import "character.dart";
import "entity.dart";
import "game.dart";
import "position.dart";
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

    if (Game.currentZoning != null && Game.currentZoning.inProgress) {
      Game.currentZoning.step(Game.currentTime);
    }
  }

  void updateZoning() {
    int s = 3;
    int ts = 16;
    int speed = 500;

    if (Game.currentZoning == null || Game.currentZoning.inProgress) {
      return;
    }

    Orientation orientation = Game.zoningOrientation;
    int startValue = 0;
    int endValue = 0;
    int offset = 0;
    Function updateFunc;
    Function endFunc;

    if (orientation == Orientation.LEFT || orientation == Orientation.RIGHT) {
      offset = (Game.camera.gridW - 2) * ts;
      startValue = (orientation == Orientation.LEFT) ? Game.camera.x - ts : Game.camera.x + ts;
      endValue = (orientation == Orientation.LEFT) ? Game.camera.x - offset : Game.camera.x + offset;
      updateFunc = (x) {
        Game.camera.setPosition(x, Game.camera.y);
        Game.initAnimatedTiles();
        Game.renderer.renderStaticCanvases();
      };
      endFunc = () {
        Game.camera.setPosition(Game.currentZoning.endValue, Game.camera.y);
        Game.endZoning();
      };
    } else if (orientation == Orientation.UP || orientation == Orientation.DOWN) {
      offset = (Game.camera.gridH - 2) * ts;
      startValue = (orientation == Orientation.UP) ? Game.camera.y - ts : Game.camera.y + ts;
      endValue = (orientation == Orientation.UP) ? Game.camera.y - offset : Game.camera.y + offset;
      updateFunc = (y) {
        Game.camera.setPosition(Game.camera.x, y);
        Game.initAnimatedTiles();
        Game.renderer.renderStaticCanvases();
      };
      endFunc = () {
        Game.camera.setPosition(Game.camera.x, Game.currentZoning.endValue);
        Game.endZoning();
      };
    }

    Game.currentZoning.start(Game.currentTime, updateFunc, endFunc, startValue, endValue, speed);
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
      if (entity.currentAnimation != null && entity.currentAnimation.update(Game.currentTime)) {
        entity.dirty();
      }
    });

    if (Game.sparksAnimation != null) {
      Game.sparksAnimation.update(Game.currentTime);
    }

    if (Game.targetAnimation != null) {
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
    if (Game.player == null || Game.player.isMoving()) {
      return;
    }

    Game.selectedCellVisible = false;

    Position pos = Game.player.gridPosition;

    switch (Game.player.direction) {
      case Orientation.UP:
        Game.keys(new Position(pos.x, pos.y-1), Orientation.UP);
        break;

      case Orientation.DOWN:
        Game.keys(new Position(pos.x, pos.y+1), Orientation.DOWN);
        break;

      case Orientation.RIGHT:
        Game.keys(new Position(pos.x+1, pos.y), Orientation.RIGHT);
        break;

      case Orientation.LEFT:
        Game.keys(new Position(pos.x-1, pos.y), Orientation.LEFT);
        break;
    }
  }
}
