library animatedtile;

import "animationtimer.dart";
import "tile.dart";
import "game.dart";
import "position.dart";

class AnimatedTile extends Tile {

  int id;
  int startID;
  int length;
  int speed;
  int index;
  AnimationTimer timer;

  AnimatedTile(
    Position position, 
    int this.id, 
    int this.length, 
    int this.speed, 
    int this.index
  ): super(position) {
    this.timer = new AnimationTimer(new Duration(milliseconds: this.speed));
    this.timer.on("Tick", () {
      this.id = (this.id + 1) % this.length;
      this.isDirty = true;
      this.dirtyRect = Game.renderer.getTileBoundingRect(this);
      Game.checkOtherDirtyRects(this.dirtyRect, this, this.position);
    });
  }

  void update(int time) {
    this.timer.update(time);
  }
}