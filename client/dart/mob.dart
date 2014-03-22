library mob;

import "character.dart";
import "entity.dart";
import "game.dart";
import "player.dart";
import "../shared/dart/gametypes.dart";

class Mob extends Character {

  int aggroRange = 1;
  bool isAggressive = true;
  bool targetable = true;

  Mob(int id, Entities kind): super(id, kind);

  bool isHostile(Entity entity) => (entity is Player);

  void die() {
    // TODO: implement a proper function receive deathpositions @ Game class
    // Keep track of where mobs die in order to spawn their dropped items
    // at the right position later.
    Game.deathpositions[this.id] = this.gridPosition;

    super.die();
  }
}
