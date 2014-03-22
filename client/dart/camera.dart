library camera;

import "base.dart";
import "entity.dart";
import "renderer.dart";

class Camera extends Base {

  Renderer renderer;
  int x = 0;
  int y = 0;
  int gridX = 0;
  int gridY = 0;
  int gridW;
  int gridH;
  num offset = 0.5;

  Camera(Renderer this.renderer) {
    this.rescale();
  }

  void rescale() {
    int factor = this.renderer.mobile ? 1 : 2;

    this.gridW = 15 * factor;
    this.gridH = 7 * factor;
  }

  void setPosition(int x, int y) {
    this.x = x;
    this.y = y;

    this.gridX = (x / 16).floor();
    this.gridY = (y / 16).floor();
  }

  void setGridPosition(int x, int y) {
    this.gridX = x;
    this.gridY = y;

    this.x = this.gridX * 16;
    this.y = this.gridY * 16;
  }

  void lookAt(Entity entity) {
    int x = (entity.x - ((this.gridW / 2).floor() * this.renderer.tilesize)).round();
    int y = (entity.y - ((this.gridH / 2).floor() * this.renderer.tilesize)).round();

    this.setPosition(x, y);
  }

  void forEachVisiblePosition(void callback(int x, int y), [int extra = 0]) {
    int maxY = this.gridY + this.gridH + (extra * 2);
    int maxX = this.gridX + this.gridW + (extra * 2);
    for (int y = this.gridY - extra; y < maxY; y++) {
      for (int x = this.gridX - extra; x < maxX; x++) {
        callback(x, y);
      }
    }
  }

  bool isVisible(Entity entity) => 
    this.isVisiblePosition(entity.gridX, entity.gridY);

  bool isVisiblePosition(int x, int y) =>
    (y >= this.gridY 
     && y < this.gridY + this.gridH 
     && x >= this.gridX 
     && x < this.gridX + this.gridW);

  void focusEntity(Entity entity) {
    int w = this.gridW - 2;
    int h = this.gridH - 2;
    int x = ((entity.gridX - 1) / w).floor() * w;
    int y = ((entity.gridY - 1) / h).floor() * h;

    this.setGridPosition(x, y);
  }
}
