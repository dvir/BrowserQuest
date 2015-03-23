library mob;

import "character.dart";
import "entity.dart";
import "game.dart";
import "player.dart";
import "lib/gametypes.dart";

class Mob extends Character {

  bool isAggressive = true;
  bool targetable = true;

  Mob(int id, EntityKind kind): super(id, kind);

  bool isHostile(Entity entity) => (entity is Player);

  void die() {
    Game.registerEntityDeathPosition(this);

    super.die();
  }
}
