library info;

import "animationtimer.dart";
import "base.dart";
import "lib/gametypes.dart";

class Info extends Base {

  int duration = 1000;
  int x;
  int y;
  num opacity = 1;
  int speed = 100;
  String value;
  AnimationTimer timer;
  String fillColor;
  String strokeColor;
  Orientation direction;

  Info(String this.value, int this.x, int this.y);

  void tick() {
    this.y--;

    switch (this.direction) {
      case Orientation.LEFT:
        this.x--;
        break;
      case Orientation.RIGHT:
        this.x++;
        break;

      case Orientation.UP:
      case Orientation.DOWN:
      default:
        break;
    }

    this.opacity -= 0.07;
    if (this.opacity < 0) {
      this.trigger("Destroy");
    }
  }

  void init() {
    this.timer = new AnimationTimer(new Duration(milliseconds: this.speed));
    this.timer.on("Tick", this.tick);
  }
  
  void update(num time) {
    this.timer.update(time);
  }
}
