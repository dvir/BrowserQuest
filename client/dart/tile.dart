library tile;

import "base.dart";

class Tile extends Base {

  int x;
  int y;
  bool isDirty = false;
  var dirtyRect;

  Tile (int this.x, int this.y);
}
