library animationtimer;

import "base.dart";
import "game.dart";

// TODO: save all instances of animationtimers in a static field
// and update them all together when a time is given
class AnimationTimer extends Base {

  Duration duration;
  int lastTime = 0;

  AnimationTimer(Duration this.duration) {
    this.reset();
  }

  void update(int time) {
    if ((time - this.lastTime) > this.duration.inMilliseconds) {
      this.lastTime = time;
      this.trigger("Tick");
      this.trigger("Over");
    }
  }

  void reset() {
    this.lastTime = Game.currentTime;
  }
}
