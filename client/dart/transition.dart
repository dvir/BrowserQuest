library transition;

import "dart:html";

import "base.dart";

class Transition extends Base {
  int startTime = 0;
  int startValue = 0;
  int endValue = 0;
  int duration = 0;
  bool inProgress = false;
  int count = 0;

  void start(int currentTime, 
             Function updateFunction, 
             Function stopFunction, 
             int startValue, 
             int endValue, 
             int duration) {
    this.startTime = currentTime;
    this.on("Update", updateFunction, true);
    this.on("Stop", stopFunction, true);
    this.startValue = startValue;
    this.endValue = endValue;
    this.duration = duration;
    this.inProgress = true;
    this.count = 0;
  }

  void step(int currentTime) {
    if (this.inProgress) {
      if (this.count > 0) {
        this.count -= 1;
        window.console.debug("${currentTime}: jumped frame");
      } else {
        int elapsed = currentTime - this.startTime;

        if (elapsed > this.duration) {
          elapsed = this.duration;
        }

        int diff = this.endValue - this.startValue;
        num i = this.startValue + ((diff / this.duration) * elapsed);

        i = i.round();

        if (elapsed == this.duration || i == this.endValue) {
          this.stop();
          this.trigger("Stop");
        } else {
          this.trigger("Update", [i]);
        }
      }
    }
  }

  void restart(int currentTime, int startValue, int endValue) {
    this.startTime = currentTime;
    this.startValue = startValue;
    this.endValue = endValue;

    this.step(currentTime);
  }

  void stop() {
    this.inProgress = false;
  }
}
