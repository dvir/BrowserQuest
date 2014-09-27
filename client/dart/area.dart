library area;

import "base.dart";
import "entity.dart";

class Area extends Base {
  
  int x;
  int y;
  int width;
  int height;
  String musicName;

  Area(int this.x, int this.y, int this.width, int this.height, [String this.musicName]);

  bool contains(Entity entity) =>
    entity.gridPosition.x >= this.x
    && entity.gridPosition.y >= this.y
    && entity.gridPosition.x < (this.x + this.width)
    && entity.gridPosition.y < (this.y + this.height);

}
