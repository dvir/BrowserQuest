library animation;

import "base.dart";

class Frame {
  int index = 0;
  int x = 0;
  int y = 0;

  Frame(int index, int x, int y) {
    this.index = index;
    this.x = x;
    this.y = y;
  }
}

class Animation extends Base {
  
  static const String IDLE_DOWN = "idle_down";
  
  String name;
  int length;
  int row;
  int width;
  int height;
  int speed = 0;
  int count = 0;
  num lastTime;
  Frame currentFrame;

  Animation(String this.name, int this.length, int this.row, int this.width, int this.height) {
    this.reset();
  }

  void tick() {
    int i = (this.currentFrame.index + 1) % this.length;

    if (this.count > 0 && i == 0) {
      this.count--;
      if (this.count == 0) {
        this.currentFrame.index = 0;
        this.trigger("EndCount");
        return;
      }
    }

    this.currentFrame.x = this.width * i;
    this.currentFrame.y = this.height * this.row;
    this.currentFrame.index = i;
  }

  bool isTimeToAnimate(num time) => ((time - this.lastTime) > this.speed);

  bool update(num time) {
    if (this.lastTime == 0 && this.name.substring(0, 3) == "atk") {
      this.lastTime = time;
    }

    if (this.isTimeToAnimate(time)) {
      this.lastTime = time;
      this.tick();
      return true;
    }

    return false;
  }

  void reset() {
    this.lastTime = 0;
    this.currentFrame = new Frame(0, 0, this.row * this.height);
  }
}
