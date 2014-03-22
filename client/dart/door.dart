library door;

import "../shared/dart/gametypes.dart";

class Door {

  int x;
  int y;
  Orientation orientation;
  int cameraX;
  int cameraY;
  bool isPortal;

  Door(
    int this.x,
    int this.y,
    Orientation this.orientation,
    int this.cameraX,
    int this.cameraY,
    bool this.isPortal
  );
}

