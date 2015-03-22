library chest;

import "entity.dart";
import "lib/gametypes.dart";

class Chest extends Entity {

  Chest(int id): super(id, Entities.CHEST);

  bool isMoving() => false;

  void open() {
    this.stopBlinking();
    this.die();
  }
}
