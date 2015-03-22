library camera;

import "base.dart";
import "entity.dart";
import "position.dart";
import "renderer.dart";

class Camera extends Base {

  Renderer renderer;
  Position _gridPosition = const Position.zero();
  int gridW;
  int gridH;
  num offset = 0.5;

  Camera(Renderer this.renderer) {
    this.rescale();
  }

  void rescale() {
    int factor = 2;

    this.gridW = 15 * factor;
    this.gridH = 7 * factor;
  }

  int get x => this.gridPosition.x * 16;
  void set x(int x) {
    this.gridPosition = new Position((x / 16).floor(), this.gridPosition.y);
  }

  int get y => this.gridPosition.y * 16;
  void set y(int y) {
    this.gridPosition = new Position(this.gridPosition.x, (y / 16).floor());
  }

  Position get gridPosition => this._gridPosition;
  void set gridPosition(Position position) {
    this._gridPosition = position;
    this.trigger("PositionChange");
  }

  void lookAt(Entity entity) {
    int x = (entity.x - ((this.gridW / 2).floor() * this.renderer.tilesize)).round();
    int y = (entity.y - ((this.gridH / 2).floor() * this.renderer.tilesize)).round();

    this.x = x;
    this.y = y;
  }

  void forEachVisiblePosition(void callback(Position), [int extra = 0]) {
    int maxY = this.gridPosition.y + this.gridH + (extra * 2);
    int maxX = this.gridPosition.x + this.gridW + (extra * 2);
    for (int y = this.gridPosition.y - extra; y < maxY; y++) {
      for (int x = this.gridPosition.x - extra; x < maxX; x++) {
        callback(new Position(x, y));
      }
    }
  }

  bool isVisible(Entity entity) =>
    this.isVisiblePosition(entity.gridPosition.x, entity.gridPosition.y);

  bool isVisiblePosition(int x, int y) =>
    (y >= this.gridPosition.y
     && y < this.gridPosition.y + this.gridH
     && x >= this.gridPosition.x
     && x < this.gridPosition.x + this.gridW);

  void focusEntity(Entity entity) {
    int w = this.gridW - 2;
    int h = this.gridH - 2;
    int x = ((entity.gridPosition.x - 1) / w).floor() * w;
    int y = ((entity.gridPosition.y - 1) / h).floor() * h;

    this.gridPosition = new Position(x, y);
  }
}
