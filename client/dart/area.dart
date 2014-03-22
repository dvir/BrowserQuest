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
    entity.gridX >= this.x
    && entity.gridY >= this.y
    && entity.gridX < (this.x + this.width)
    && entity.gridY < (this.y + this.height);

}
