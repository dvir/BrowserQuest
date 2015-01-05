library entityfactory;

import "chest.dart";
import "entity.dart";
import "game.dart";
import "items.dart";
import "mobs.dart";
import "npcs.dart";
import "player.dart";
import "lib/gametypes.dart";

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
    Entities.SPECTRE: (int id) => new Spectre(id),
    Entities.DEATHKNIGHT: (int id) => new Deathknight(id),
    Entities.GOBLIN: (int id) => new Goblin(id),
    Entities.OGRE: (int id) => new Ogre(id),
    Entities.CRAB: (int id) => new Crab(id),
    Entities.SNAKE: (int id) => new Snake(id),
    Entities.EYE: (int id) => new Eye(id),
    Entities.BAT: (int id) => new Bat(id),
    Entities.WIZARD: (int id) => new Wizard(id),
    Entities.BOSS: (int id) => new Boss(id),

    Entities.SWORD2: (int id) => new Sword2(id),
    Entities.AXE: (int id) => new Axe(id),
    Entities.REDSWORD: (int id) => new RedSword(id),
    Entities.BLUESWORD: (int id) => new BlueSword(id),
    Entities.GOLDENSWORD: (int id) => new GoldenSword(id),
    Entities.MORNINGSTAR: (int id) => new MorningStar(id),

    Entities.LEATHERARMOR: (int id) => new LeatherArmor(id),
    Entities.MAILARMOR: (int id) => new MailArmor(id),
    Entities.PLATEARMOR: (int id) => new PlateArmor(id),
    Entities.REDARMOR: (int id) => new RedArmor(id),
    Entities.GOLDENARMOR: (int id) => new GoldenArmor(id),

    Entities.FLASK: (int id) => new Flask(id),
    Entities.FIREPOTION: (int id) => new FirePotion(id),
    Entities.BURGER: (int id) => new Burger(id),
    Entities.CAKE: (int id) => new Cake(id),
    Entities.CHEST: (int id) => new Chest(id),

    Entities.GUARD: (int id) => new Guard(id),
    Entities.KING: (int id) => new King(id),
    Entities.VILLAGEGIRL: (int id) => new VillageGirl(id),
    Entities.VILLAGER: (int id) => new Villager(id),
    Entities.CODER: (int id) => new Coder(id),
    Entities.AGENT: (int id) => new Agent(id),
    Entities.RICK: (int id) => new Rick(id),
    Entities.SCIENTIST: (int id) => new Scientist(id),
    Entities.NYAN: (int id) => new Nyan(id),
    Entities.PRIEST: (int id) => new Priest(id),
    Entities.SORCERER: (int id) => new Sorcerer(id),
    Entities.OCTOCAT: (int id) => new Octocat(id),
    Entities.BEACHNPC: (int id) => new Surfer(id),
    Entities.FORESTNPC: (int id) => new ForestKeeper(id),
    Entities.DESERTNPC: (int id) => new Traveler(id),
    Entities.LAVANPC: (int id) => new Geologist(id),
  };

  static Entity createEntity(EntityKind kind, int id, [String name]) {
    if (!EntityFactory.builders.containsKey(kind)) {
      throw "kind ${kind} is not a valid Entity type";
    }

    if (kind == Entities.PLAYER) {
      return EntityFactory.builders[Entities.PLAYER](id, name);
    }

    return EntityFactory.builders[kind](id);
  }
}
