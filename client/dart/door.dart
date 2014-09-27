library door;

import "position.dart";
import "lib/gametypes.dart";

class Door {

  Position position;
  Orientation orientation;
  Position cameraPosition;
  bool isPortal;

  Door(
    Position this.position,
    Orientation this.orientation,
    Position this.cameraPosition,
    bool this.isPortal
  );
}

