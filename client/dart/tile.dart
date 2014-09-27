library tile;

import "base.dart";
import "position.dart";
import "rect.dart";

class Tile extends Base {

  Position position;
  bool isDirty = false;
  Rect dirtyRect;

  Tile (Position this.position);
}
