library animatedtile;

import "animationtimer.dart";
import "tile.dart";
import "game.dart";
import "position.dart";

class AnimatedTile extends Tile {

  int _startID;
  int _currentID = 0;

  int length;
  int speed;
  int index;
  AnimationTimer timer;

  AnimatedTile(
    Position position, 
    int this._startID, 
    int this.length, 
    int this.speed, 
    int this.index
  ): super(position) {
    this.timer = new AnimationTimer(new Duration(milliseconds: this.speed));
    this.timer.on("Tick", () {
      this._currentID = (this._currentID + 1) % this.length;
      this.isDirty = true;
      this.dirtyRect = Game.renderer.getTileBoundingRect(this);
    });
  }

  int get id => this._startID + this._currentID;

  void update(int time) {
    this.timer.update(time);
  }
}
