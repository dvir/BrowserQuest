library door;

import "position.dart";
import "lib/gametypes.dart";

class Door {

  Position position;
  Position destination;
  Orientation orientation;
  Position cameraPosition;
  bool isPortal;

  Door(
    Position this.position,
    Position this.destination,
    Orientation this.orientation,
    Position this.cameraPosition,
    bool this.isPortal
  );
}

