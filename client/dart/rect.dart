library rect;

class Rect {

  int x;
  int y;
  int w;
  int h;

  Rect(int this.x, int this.y, int this.w, int this.h);

  int get left => this.x;
  int get right => this.x + this.w;
  int get top => this.y;
  int get bottom => this.y + this.h;

  bool isIntersecting(Rect other) =>
    !((other.left > this.right) ||
      (other.right < this.left) ||
      (other.top > this.bottom) ||
      (other.bottom < this.top));
}

