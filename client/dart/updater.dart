library updater;

import "dart:async";

import "animatedtile.dart";
import "base.dart";
import "character.dart";
import "entity.dart";
import "game.dart";
import "position.dart";
import "lib/gametypes.dart";

class Updater extends Base {

  void update() {
    int t = Game.currentTime;

    this.updateZoning(t);
    this.updateCharacters(t);
    this.updateTransitions(t);
    this.updateAnimations(t);
    this.updateAnimatedTiles(t);
    this.updateChatBubbles(t);
    this.updateInfos(t);
    this.updateKeyboardMovement(t);
  }

  void updateCharacters(int t) {
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

  void updateTransitions(int t) {
    Game.forEachCharacter((Character character) {
      if (character.movement.inProgress) {
        character.movement.step(t);
      }
    });

    if (Game.currentZoning != null && Game.currentZoning.inProgress) {
      Game.currentZoning.step(t);
    }
  }

  void updateZoning(int t) {
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
        Game.camera.x = x;
        Game.initAnimatedTiles();
        Game.renderer.renderStaticCanvases();
      };
      endFunc = () {
	Game.camera.x = Game.currentZoning.endValue;
        Game.endZoning();
      };
    } else if (orientation == Orientation.UP || orientation == Orientation.DOWN) {
      offset = (Game.camera.gridH - 2) * ts;
      startValue = (orientation == Orientation.UP) ? Game.camera.y - ts : Game.camera.y + ts;
      endValue = (orientation == Orientation.UP) ? Game.camera.y - offset : Game.camera.y + offset;
      updateFunc = (y) {
	Game.camera.y = y;
        Game.initAnimatedTiles();
        Game.renderer.renderStaticCanvases();
      };
      endFunc = () {
	Game.camera.y = Game.currentZoning.endValue;
        Game.endZoning();
      };
    }

    Game.currentZoning.start(t, updateFunc, endFunc, startValue, endValue, speed);
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

  void updateAnimations(int t) {
    Game.forEachEntity((Entity entity) {
      if (entity.currentAnimation != null && entity.currentAnimation.update(t)) {
        entity.dirty();
      }
    });

    if (Game.sparksAnimation != null) {
      Game.sparksAnimation.update(t);
    }

    if (Game.targetAnimation != null) {
      Game.targetAnimation.update(t);
    }
  }

  void updateAnimatedTiles(int t) {
    Game.forEachAnimatedTile((AnimatedTile tile) {
      tile.update(t);
    });
  }

  void updateChatBubbles(int t) {
    Game.bubbleManager.update(t);
  }

  void updateInfos(int t) {
    Game.infoManager.update(t);
  }

  void updateKeyboardMovement(int t) {
    if (Game.player == null || Game.player.isMoving()) {
      return;
    }

    Game.selectedCellVisible = false;

    Position pos = Game.player.gridPosition;
    List<Orientation> directions = Game.player.directions.toList();
    Orientation direction = directions.isEmpty ? null : directions.last; 

    switch (direction) {
      case Orientation.UP:
        Game.keys(pos.decY(), Orientation.UP);
        break;

      case Orientation.DOWN:
        Game.keys(pos.incY(), Orientation.DOWN);
        break;

      case Orientation.RIGHT:
        Game.keys(pos.incX(), Orientation.RIGHT);
        break;

      case Orientation.LEFT:
        Game.keys(pos.decX(), Orientation.LEFT);
        break;
    }
  }
}
