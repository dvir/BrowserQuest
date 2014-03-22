library entityfactory;

import "chest.dart";
import "entity.dart";
import "game.dart";
import "hero.dart";
import "items.dart";
import "mobs.dart";
import "npcs.dart";
import "player.dart";
import "../shared/dart/gametypes.dart";

class EntityFactory {

  static Map<Entities, Function> builders = {
    Entities.PLAYER: (int id, String name) {
      if (Game.player.id == id) {
        return Game.player;
      }

      return new Player(id, name, Entities.PLAYER);
    },
    Entities.RAT: (int id) => new Rat(id),
    Entities.SKELETON: (int id) => new Skeleton(id),
    Entities.SKELETON2: (int id) => new SkeletonWarrior(id),
    Entities.SPECTRE: (int id) => new Skeleton(id),
    Entities.DEATHKNIGHT: (int id) => new Skeleton(id),
    Entities.GOBLIN: (int id) => new Skeleton(id),
    Entities.OGRE: (int id) => new Skeleton(id),
    Entities.CRAB: (int id) => new Skeleton(id),
    Entities.SNAKE: (int id) => new Skeleton(id),
    Entities.EYE: (int id) => new Skeleton(id),
    Entities.BAT: (int id) => new Skeleton(id),
    Entities.WIZARD: (int id) => new Skeleton(id),
    Entities.BOSS: (int id) => new Skeleton(id),

    Entities.SWORD2: (int id) => new Skeleton(id),
    Entities.AXE: (int id) => new Skeleton(id),
    Entities.REDSWORD: (int id) => new Skeleton(id),
    Entities.BLUESWORD: (int id) => new Skeleton(id),
    Entities.GOLDENSWORD: (int id) => new Skeleton(id),
    Entities.MORNINGSTAR: (int id) => new Skeleton(id),

    Entities.LEATHERARMOR: (int id) => new Skeleton(id),
    Entities.MAILARMOR: (int id) => new Skeleton(id),
    Entities.PLATEARMOR: (int id) => new Skeleton(id),
    Entities.REDARMOR: (int id) => new Skeleton(id),
    Entities.GOLDENARMOR: (int id) => new Skeleton(id),

    Entities.FLASK: (int id) => new Skeleton(id),
    Entities.FIREPOTION: (int id) => new Skeleton(id),
    Entities.BURGER: (int id) => new Skeleton(id),
    Entities.CAKE: (int id) => new Skeleton(id),
    Entities.CHEST: (int id) => new Skeleton(id),

    Entities.GUARD: (int id) => new Skeleton(id),
    Entities.KING: (int id) => new Skeleton(id),
    Entities.VILLAGEGIRL: (int id) => new Skeleton(id),
    Entities.VILLAGER: (int id) => new Skeleton(id),
    Entities.CODER: (int id) => new Skeleton(id),
    Entities.AGENT: (int id) => new Skeleton(id),
    Entities.RICK: (int id) => new Skeleton(id),
    Entities.SCIENTIST: (int id) => new Skeleton(id),
    Entities.NYAN: (int id) => new Skeleton(id),
    Entities.PRIEST: (int id) => new Skeleton(id),
    Entities.SORCERER: (int id) => new Skeleton(id),
    Entities.OCTOCAT: (int id) => new Skeleton(id),
    Entities.BEACHNPC: (int id) => new Skeleton(id),
    Entities.FORESTNPC: (int id) => new Skeleton(id),
    Entities.DESERTNPC: (int id) => new Skeleton(id),
    Entities.LAVANPC: (int id) => new Skeleton(id),
  };

  static Entity createEntity(Entities kind, int id, [String name]) {
    if (!EntityFactory.builders.containsKey(kind)) {
      throw "kind ${kind} is not a valid Entity type";
    }

    if (kind == Entities.PLAYER) {
      return EntityFactory.builders[Entities.PLAYER](id, name);
    }

    return EntityFactory.builders[kind](id);
  }
}
