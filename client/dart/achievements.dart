library achievements;

import "game.dart";
import "lib/gametypes.dart";

class Achievement {

  final int id;
  final String name;
  final String description;
  final bool hidden;

  const Achievement(
    int this.id, 
    String this.name, 
    String this.description, 
    {bool this.hidden: false}
  );

  static const A_TRUE_WARRIOR = const Achievement(1, "A True Warrior", "Find a new weapon");
  static const INTO_THE_WILD = const Achievement(2, "Into the Wild", "Venture outside the village");
  static const ANGRY_RATS = const Achievement(3, "Angry Rats", "Kill 10 rats");
  static const SMALL_TALK = const Achievement(4, "Small Talk", "Talk to a non-player character");
  static const FAT_LOOT = const Achievement(5, "Fat Loot", "Get a new armor set");
  static const UNDERGROUND = const Achievement(6, "Underground", "Explore at least one cave");
  static const AT_WORLDS_END = const Achievement(7, "At World's End", "Reach the south shore");
  static const COWARD = const Achievement(8, "Coward", "Successfully escape an enemy");
  static const TOMB_RAIDER = const Achievement(9, "Tomb Raider", "Find the graveyard");
  static const SKULL_COLLECTOR = const Achievement(10, "Skull Collector", "Kill 10 skeletons");
  static const NINJA_LOOT = const Achievement(11, "Ninja Loot", "Get hold of an item you didn't fight for");
  static const NO_MANS_LAND = const Achievement(12, "No Man's Land", "Travel through the desert");
  static const HUNTER = const Achievement(13, "Hunter", "Kill 50 enemies");
  static const STILL_ALIVE = const Achievement(14, "Still Alive", "Revive your character five times"); 
  static const MEATSHIELD = const Achievement(15, "Meatshield", "Take 5,000 points of damage");
  static const HOT_SPOT = const Achievement(16, "Hot Spot", "Enter the volcanic mountains");
  static const HERO = const Achievement(17, "Hero", "Defeat the final boss");
  static const FOXY = const Achievement(18, "Foxy", "Find the Firefox costume", hidden: true);
  static const FOR_SCIENCE = const Achievement(19, "For Science", "Enter into a portal", hidden: true);
  static const RICKROLLD = const Achievement(20, "Rickroll'd", "Take some singing lessons", hidden: true);

  static final Map<int, Achievement> _achievements = {
    A_TRUE_WARRIOR.id: A_TRUE_WARRIOR,
    INTO_THE_WILD.id: INTO_THE_WILD,
    ANGRY_RATS.id: ANGRY_RATS,
    SMALL_TALK.id: SMALL_TALK,
    FAT_LOOT.id: FAT_LOOT,
    UNDERGROUND.id: UNDERGROUND,
    AT_WORLDS_END.id: AT_WORLDS_END,
    COWARD.id: COWARD,
    TOMB_RAIDER.id: TOMB_RAIDER,
    SKULL_COLLECTOR.id: SKULL_COLLECTOR,
    NINJA_LOOT.id: NINJA_LOOT,
    NO_MANS_LAND.id: NO_MANS_LAND,
    HUNTER.id: HUNTER,
    STILL_ALIVE.id: STILL_ALIVE,
    MEATSHIELD.id: MEATSHIELD,
    HOT_SPOT.id: HOT_SPOT,
    HERO.id: HERO,
    FOXY.id: FOXY,
    FOR_SCIENCE.id: FOR_SCIENCE,
    RICKROLLD.id: RICKROLLD
  };

  static final Map<Achievement, Function> _isCompletedPredicates = {
    ANGRY_RATS: () => Game.storage.getKillCount(Entities.RAT) >= 10,
    SKULL_COLLECTOR: () => Game.storage.getKillCount(Entities.SKELETON) + Game.storage.getKillCount(Entities.SKELETON2) >= 10,
    HUNTER: () => Game.storage.totalKills >= 50,
    STILL_ALIVE: () => Game.storage.totalRevives >= 5,
    MEATSHIELD: () => Game.storage.totalDamageTaken >= 5000
  };

  static Achievement getByID(int id) {
    return Achievement._achievements[id];
  }

  static void forEach(void callback(Achievement)) {
    Achievement._achievements.forEach((int id, Achievement achievement) {
      callback(achievement);
    });
  }

  bool isCompleted() {
    return _isCompletedPredicates.containsKey(this) ? _isCompletedPredicates[this]() : false;
  }
}
