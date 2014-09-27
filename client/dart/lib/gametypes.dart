library gametypes;

import "dart:math";

class Message {
  final int index;
  const Message(int this.index);

  static const HELLO = const Message(0);
  static const WELCOME = const Message(1);
  static const SPAWN = const Message(2);
  static const DESPAWN = const Message(3);
  static const MOVE = const Message(4);
  static const LOOTMOVE = const Message(5);
  static const AGGRO = const Message(6);
  static const ATTACK = const Message(7);
  static const HIT = const Message(8);
  static const HURT = const Message(9);
  static const HEALTH = const Message(10);
  static const CHAT = const Message(11);
  static const LOOT = const Message(12);
  static const EQUIP = const Message(13);
  static const DROP = const Message(14);
  static const TELEPORT = const Message(15);
  static const DAMAGE = const Message(16);
  static const POPULATION = const Message(17);
  static const KILL = const Message(18);
  static const LIST = const Message(19);
  static const WHO = const Message(20);
  static const ZONE = const Message(21);
  static const DESTROY = const Message(22);
  static const BLINK = const Message(24);
  static const OPEN = const Message(25);
  static const CHECK = const Message(26);
  static const XP = const Message(27);
  static const LEVEL = const Message(28);
  static const DATA = const Message(29);
  static const INVENTORY = const Message(30);
  static const INVENTORYITEM = const Message(31);
  static const INVENTORYSWAP = const Message(32);
  static const USE = const Message(33);
  static const USEITEM = const Message(34);
  static const USESPELL = const Message(35);
  static const SKILLBAR = const Message(36);
  static const THROWITEM = const Message(37);
  static const RESURRECT = const Message(38);
  static const PLAYER_ENTER = const Message(39);
  static const PLAYER_EXIT = const Message(40);
  static const PLAYERS = const Message(41);
  static const PARTY_JOIN = const Message(42);
  static const PARTY_INITIAL_JOIN = const Message(43);
  static const PARTY_LEAVE = const Message(44);
  static const PARTY_INVITE = const Message(45);
  static const PARTY_KICK = const Message(46);
  static const PARTY_LEADER_CHANGE = const Message(47);
  static const PARTY_ACCEPT = const Message(48);
  static const GUILD_JOIN = const Message(49);
  static const GUILD_ONLINE = const Message(50);
  static const GUILD_QUIT = const Message(51);
  static const GUILD_INVITE = const Message(52);
  static const GUILD_KICK = const Message(53);
  static const GUILD_LEADER_CHANGE = const Message(54);
  static const GUILD_ACCEPT = const Message(55);
  static const GUILD_CREATE = const Message(56);
  static const GUILD_MEMBERS = const Message(57);
  static const GUILD_JOINED = const Message(58);
  static const GUILD_LEFT = const Message(59);
  static const GUILD_OFFLINE = const Message(60);
  static const PLAYER_UPDATE = const Message(61);
  static const DEFEATED = const Message(62);

  static const COMMAND_NOTICE = const Message(9998);
  static const COMMAND_ERROR = const Message(9999);
  static const ERROR = const Message(10000);
}

class Entities {
  final int index;
  const Entities(int this.index);

  static const PLAYER = const Entities(1);
  
  // Mobs
  static const RAT = const Entities(2);
  static const SKELETON = const Entities(3);
  static const GOBLIN = const Entities(4);
  static const OGRE = const Entities(5);
  static const SPECTRE = const Entities(6);
  static const CRAB = const Entities(7);
  static const BAT = const Entities(8);
  static const WIZARD = const Entities(9);
  static const EYE = const Entities(10);
  static const SNAKE = const Entities(11);
  static const SKELETON2 = const Entities(12);
  static const BOSS = const Entities(13);
  static const DEATHKNIGHT = const Entities(14);
  
  // Armors
  static const FIREFOX = const Entities(20);
  static const CLOTHARMOR = const Entities(21);
  static const LEATHERARMOR = const Entities(22);
  static const MAILARMOR = const Entities(23);
  static const PLATEARMOR = const Entities(24);
  static const REDARMOR = const Entities(25);
  static const GOLDENARMOR = const Entities(26);
  
  // Objects
  static const FLASK = const Entities(35);
  static const BURGER = const Entities(36);
  static const CHEST = const Entities(37);
  static const FIREPOTION = const Entities(38);
  static const CAKE = const Entities(39);
  
  // NPCs
  static const GUARD = const Entities(40);
  static const KING = const Entities(41);
  static const OCTOCAT = const Entities(42);
  static const VILLAGEGIRL = const Entities(43);
  static const VILLAGER = const Entities(44);
  static const PRIEST = const Entities(45);
  static const SCIENTIST = const Entities(46);
  static const AGENT = const Entities(47);
  static const RICK = const Entities(48);
  static const NYAN = const Entities(49);
  static const SORCERER = const Entities(50);
  static const BEACHNPC = const Entities(51);
  static const FORESTNPC = const Entities(52);
  static const DESERTNPC = const Entities(53);
  static const LAVANPC = const Entities(54);
  static const CODER = const Entities(55);
  
  // Weapons
  static const SWORD1 = const Entities(60);
  static const SWORD2 = const Entities(61);
  static const REDSWORD = const Entities(62);
  static const GOLDENSWORD = const Entities(63);
  static const MORNINGSTAR = const Entities(64);
  static const AXE = const Entities(65);
  static const BLUESWORD = const Entities(66);

  // Spells
  static const FROSTNOVA = const Entities(100);
  static const FROSTBOLT = const Entities(101);
  static const ICEBARRIER = const Entities(102);
  static const FIREBALL = const Entities(103);
  static const BLINK = const Entities(104);
  static const POLYMORPH = const Entities(105);

  // using this so I won't have to mess with ending commas
  static const UNKNOWN = const Entities(999);
  static const DEATH = const Entities(9999);
}

class Orientation {
  final int index;
  const Orientation(int this.index);

  static const UP = const Orientation(1);
  static const DOWN = const Orientation(2);
  static const LEFT = const Orientation(3);
  static const RIGHT = const Orientation(4);
}

class Keys {
  final int index;
  const Keys(int this.index);

  static const ENTER = const Keys(13);
  static const ESC = const Keys(27);
  static const UP = const Keys(38);
  static const DOWN = const Keys(40);
  static const LEFT = const Keys(37);
  static const RIGHT = const Keys(39);
  static const W = const Keys(87);
  static const A = const Keys(65);
  static const S = const Keys(83);
  static const D = const Keys(68);
  static const TAB = const Keys(9);
  static const SPACE = const Keys(32);
  static const F = const Keys(70);
  static const H = const Keys(72);
  static const I = const Keys(73);
  static const K = const Keys(75);
  static const M = const Keys(77);
  static const P = const Keys(80);
  static const T = const Keys(84);
  static const Y = const Keys(89);
  static const KEYPAD_4 = const Keys(100);
  static const KEYPAD_6 = const Keys(102);
  static const KEYPAD_8 = const Keys(104);
  static const KEYPAD_2 = const Keys(98);
  static const SLASH = const Keys(191);
}

class Types {

  static var kinds = {
    "unknown": [Entities.UNKNOWN, "unknown"],

    "death": [Entities.DEATH, "death"],

    "player": [Entities.PLAYER, "player"],

    "rat": [Entities.RAT, "mob"],
    "skeleton": [Entities.SKELETON , "mob"],
    "goblin": [Entities.GOBLIN, "mob"],
    "ogre": [Entities.OGRE, "mob"],
    "spectre": [Entities.SPECTRE, "mob"],
    "deathknight": [Entities.DEATHKNIGHT, "mob"],
    "crab": [Entities.CRAB, "mob"],
    "snake": [Entities.SNAKE, "mob"],
    "bat": [Entities.BAT, "mob"],
    "wizard": [Entities.WIZARD, "mob"],
    "eye": [Entities.EYE, "mob"],
    "skeleton2": [Entities.SKELETON2, "mob"],
    "boss": [Entities.BOSS, "mob"],

    "sword1": [Entities.SWORD1, "weapon"],
    "sword2": [Entities.SWORD2, "weapon"],
    "axe": [Entities.AXE, "weapon"],
    "redsword": [Entities.REDSWORD, "weapon"],
    "bluesword": [Entities.BLUESWORD, "weapon"],
    "goldensword": [Entities.GOLDENSWORD, "weapon"],
    "morningstar": [Entities.MORNINGSTAR, "weapon"],

    "firefox": [Entities.FIREFOX, "armor"],
    "clotharmor": [Entities.CLOTHARMOR, "armor"],
    "leatherarmor": [Entities.LEATHERARMOR, "armor"],
    "mailarmor": [Entities.MAILARMOR, "armor"],
    "platearmor": [Entities.PLATEARMOR, "armor"],
    "redarmor": [Entities.REDARMOR, "armor"],
    "goldenarmor": [Entities.GOLDENARMOR, "armor"],

    "flask": [Entities.FLASK, "object"],
    "cake": [Entities.CAKE, "object"],
    "burger": [Entities.BURGER, "object"],
    "chest": [Entities.CHEST, "object"],
    "firepotion": [Entities.FIREPOTION, "object"],

    "guard": [Entities.GUARD, "npc"],
    "villagegirl": [Entities.VILLAGEGIRL, "npc"],
    "villager": [Entities.VILLAGER, "npc"],
    "coder": [Entities.CODER, "npc"],
    "scientist": [Entities.SCIENTIST, "npc"],
    "priest": [Entities.PRIEST, "npc"],
    "king": [Entities.KING, "npc"],
    "rick": [Entities.RICK, "npc"],
    "nyan": [Entities.NYAN, "npc"],
    "sorcerer": [Entities.SORCERER, "npc"],
    "agent": [Entities.AGENT, "npc"],
    "octocat": [Entities.OCTOCAT, "npc"],
    "beachnpc": [Entities.BEACHNPC, "npc"],
    "forestnpc": [Entities.FORESTNPC, "npc"],
    "desertnpc": [Entities.DESERTNPC, "npc"],
    "lavanpc": [Entities.LAVANPC, "npc"],

    "frostnova": [Entities.FROSTNOVA, "spell"],
    "frostbolt": [Entities.FROSTBOLT, "spell"],
    "icebarrier": [Entities.ICEBARRIER, "spell"],
    "fireball": [Entities.FIREBALL, "spell"],
    "blink": [Entities.BLINK, "spell"],
    "polymorph": [Entities.POLYMORPH, "spell"] 
  };
      
  static var rankedWeapons = [
    Entities.SWORD1,
    Entities.SWORD2,
    Entities.AXE,
    Entities.MORNINGSTAR,
    Entities.BLUESWORD,
    Entities.REDSWORD,
    Entities.GOLDENSWORD
  ];

  static var rankedArmors = [
    Entities.CLOTHARMOR,
    Entities.LEATHERARMOR,
    Entities.MAILARMOR,
    Entities.PLATEARMOR,
    Entities.REDARMOR,
    Entities.GOLDENARMOR
  ];

  static int getWeaponRank(weaponKind) {
    return Types.rankedWeapons.indexOf(weaponKind);
  }

  static int getArmorRank(armorKind) {
    return Types.rankedArmors.indexOf(armorKind);
  }

  static bool itemRankCompare(item1, item2) {
    if (Types.isArmor(item1.kind) && Types.isArmor(item2.kind)) {
        return (Types.getArmorRank(item1.kind) > Types.getArmorRank(item2.kind));
    }

    if (Types.isWeapon(item1.kind) && Types.isWeapon(item2.kind)) {
        return (Types.getWeaponRank(item1.kind) > Types.getWeaponRank(item2.kind));
    }

    throw "Cannot compare rank of items not of the same type.";
  }

  static bool isPlayer(kind) {
    return Types.getType(kind) == "player";
  }

  static bool isMob(kind) {
    return Types.getType(kind) == "mob";
  }

  static bool isNpc(kind) {
    return Types.getType(kind) == "npc";
  }

  static bool isCharacter(kind) {
    return Types.isMob(kind) || Types.isNpc(kind) || Types.isPlayer(kind);
  }

  static bool isArmor(kind) {
    return Types.getType(kind) == "armor";
  }

  static bool isWeapon(kind) {
    return Types.getType(kind) == "weapon";
  }

  static bool isStackable(kind) {
    return (kind == Entities.FLASK);
  }

  static bool isUseOnPickup(kind) {
    return (kind == Entities.FIREPOTION);
  }

  static bool isObject(kind) {
    return Types.getType(kind) == "object";
  }

  static bool isChest(kind) {
    return kind == Entities.CHEST;
  }

  static bool isItem(kind) {
    return Types.isWeapon(kind) 
           || Types.isArmor(kind) 
           || (Types.isObject(kind) && !Types.isChest(kind));
  }

  static bool isSpell(kind) {
    return (Types.getType(kind) == "spell");
  }

  static bool isHealingItem(kind) {
    return kind == Entities.FLASK 
           || kind == Entities.BURGER;
  }

  static bool isExpendableItem(kind) {
    return Types.isHealingItem(kind)
           || kind == Entities.FIREPOTION
           || kind == Entities.CAKE;
  }

  static String getType(kind) {
    if (!kind) {
      throw "Undefiend kind given to Types.getType";
    }

    if (kinds[Types.getKindAsString(kind)]) {
      return kinds[Types.getKindAsString(kind)][1];
    }

    throw "Inexistant kind given to Types.getType ${kind}";
  }

  static String getKindFromString(kind) {
    if (kinds.containsKey(kind)) {
      return kinds[kind][0];
    }

    throw "Inexistant kind given to Types.getKindFromString ${kind}";
  }

  static String getKindAsString(kind) {
    if (!kind) {
      throw "Null kind given to Types.getKindAsString ${kind}";
    }

    for (var k in kinds) {
      if (k != "getType" && kinds[k][0] == kind) {
          return k;
      }
    }

    throw "Inexistant kind given to Types.getKindAsString ${kind}";
  }

  static void forEachKind(callback) {
    for (var k in kinds) {
      callback(kinds[k][0], k);
    }
  }

  static void forEachArmor(callback) {
    Types.forEachKind((kind, kindName) {
      if (Types.isArmor(kind)) {
        callback(kind, kindName);
      }
    });
  }

  static void forEachMobOrNpcKind(callback) {
    Types.forEachKind((kind, kindName) {
      if (Types.isMob(kind) || Types.isNpc(kind)) {
        callback(kind, kindName);
      }
    });
  }

  static void forEachArmorKind(callback) {
    Types.forEachKind((kind, kindName) {
      if (Types.isArmor(kind)) {
        callback(kind, kindName);
      }
    });
  }

  static String getOrientationAsString(orientation) {
    switch(orientation) {
      case Orientation.LEFT: return "left";
      case Orientation.RIGHT: return "right";
      case Orientation.UP: return "up";
      case Orientation.DOWN: return "down";
    }

    throw "Inexistant orientation given to Types.getOrientationAsString ${orientation}";
  }

  static Entities getRandomItemKind(item) {
    var rng = new Random();
    List<Entities> all = new List<Entities>();
    all.addAll(rankedWeapons);
    all.addAll(rankedArmors);
    all.remove(Entities.SWORD1);
    all.remove(Entities.CLOTHARMOR);
    int randIndex = rng.nextInt(all.length).floor();
    
    return all[randIndex];
  }
}
