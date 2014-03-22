library animatedtile;

import "dart:async";

import "animationtimer.dart";
import "tile.dart";
import "game.dart";

class AnimatedTile extends Tile {

  int id;
  int startID;
  int length;
  int speed;
  int index;
  AnimationTimer timer;

  AnimatedTile(
    int x, 
    int y, 
    int this.id, 
    int this.length, 
    int this.speed, 
    int this.index
  ): super(x, y) {
    this.timer = new AnimationTimer(new Duration(milliseconds: this.speed));
    this.timer.on("Tick", () {
      this.id = (this.id + 1) % this.length;
      this.isDirty = true;
      this.dirtyRect = Game.renderer.getTileBoundingRect(this);
      Game.checkOtherDirtyRects(this.dirtyRect, this, this.x, this.y);
    });
  }

  void update(int time) {
    this.timer.update(time);
  }
}
