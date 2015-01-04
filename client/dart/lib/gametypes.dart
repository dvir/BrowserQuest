library gametypes;

import "dart:math";

class Message {
  final int index;
  const Message(int this.index);
  toString() => 'Message.${this.index}';

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

  static EntityKind get(int index) {
    if (!_entities.containsKey(index)) {
      throw new Exception("EntityKind: unknown entity kind '${index}'.");
    }
    return _entities[index];
  }

  static Map<int, EntityKind> _entities = {
    1: EntityKind.PLAYER,
    
    // Mobs
    2: EntityKind.RAT,
    3: EntityKind.SKELETON,
    4: EntityKind.GOBLIN,
    5: EntityKind.OGRE,
    6: EntityKind.SPECTRE,
    7: EntityKind.CRAB,
    8: EntityKind.BAT,
    9: EntityKind.WIZARD,
    10: EntityKind.EYE,
    11: EntityKind.SNAKE,
    12: EntityKind.SKELETON2,
    13: EntityKind.BOSS,
    14: EntityKind.DEATHKNIGHT,
    
    // Armors
    20: EntityKind.FIREFOX,
    21: EntityKind.CLOTHARMOR,
    22: EntityKind.LEATHERARMOR,
    23: EntityKind.MAILARMOR,
    24: EntityKind.PLATEARMOR,
    25: EntityKind.REDARMOR,
    26: EntityKind.GOLDENARMOR,
    
    // Objects
    35: EntityKind.FLASK,
    36: EntityKind.BURGER,
    37: EntityKind.CHEST,
    38: EntityKind.FIREPOTION,
    39: EntityKind.CAKE,
    
    // NPCs
    40: EntityKind.GUARD,
    41: EntityKind.KING,
    42: EntityKind.OCTOCAT,
    43: EntityKind.VILLAGEGIRL,
    44: EntityKind.VILLAGER,
    45: EntityKind.PRIEST,
    46: EntityKind.SCIENTIST,
    47: EntityKind.AGENT,
    48: EntityKind.RICK,
    49: EntityKind.NYAN,
    50: EntityKind.SORCERER,
    51: EntityKind.BEACHNPC,
    52: EntityKind.FORESTNPC,
    53: EntityKind.DESERTNPC,
    54: EntityKind.LAVANPC,
    55: EntityKind.CODER,
    
    // Weapons
    60: EntityKind.SWORD1,
    61: EntityKind.SWORD2,
    62: EntityKind.REDSWORD,
    63: EntityKind.GOLDENSWORD,
    64: EntityKind.MORNINGSTAR,
    65: EntityKind.AXE,
    66: EntityKind.BLUESWORD,

    // Spells
    100: EntityKind.FROSTNOVA,
    101: EntityKind.FROSTBOLT,
    102: EntityKind.ICEBARRIER,
    103: EntityKind.FIREBALL,
    104: EntityKind.BLINK,
    105: EntityKind.POLYMORPH,

    // using this so I won't have to mess with ending commas
    999: EntityKind.UNKNOWN,
    9999: EntityKind.DEATH
  };
}

class EntityKind {
  final int index;
  const EntityKind(int this.index);

  static const PLAYER = const EntityKind(1);
  
  // Mobs
  static const RAT = const EntityKind(2);
  static const SKELETON = const EntityKind(3);
  static const GOBLIN = const EntityKind(4);
  static const OGRE = const EntityKind(5);
  static const SPECTRE = const EntityKind(6);
  static const CRAB = const EntityKind(7);
  static const BAT = const EntityKind(8);
  static const WIZARD = const EntityKind(9);
  static const EYE = const EntityKind(10);
  static const SNAKE = const EntityKind(11);
  static const SKELETON2 = const EntityKind(12);
  static const BOSS = const EntityKind(13);
  static const DEATHKNIGHT = const EntityKind(14);
  
  // Armors
  static const FIREFOX = const EntityKind(20);
  static const CLOTHARMOR = const EntityKind(21);
  static const LEATHERARMOR = const EntityKind(22);
  static const MAILARMOR = const EntityKind(23);
  static const PLATEARMOR = const EntityKind(24);
  static const REDARMOR = const EntityKind(25);
  static const GOLDENARMOR = const EntityKind(26);
  
  // Objects
  static const FLASK = const EntityKind(35);
  static const BURGER = const EntityKind(36);
  static const CHEST = const EntityKind(37);
  static const FIREPOTION = const EntityKind(38);
  static const CAKE = const EntityKind(39);
  
  // NPCs
  static const GUARD = const EntityKind(40);
  static const KING = const EntityKind(41);
  static const OCTOCAT = const EntityKind(42);
  static const VILLAGEGIRL = const EntityKind(43);
  static const VILLAGER = const EntityKind(44);
  static const PRIEST = const EntityKind(45);
  static const SCIENTIST = const EntityKind(46);
  static const AGENT = const EntityKind(47);
  static const RICK = const EntityKind(48);
  static const NYAN = const EntityKind(49);
  static const SORCERER = const EntityKind(50);
  static const BEACHNPC = const EntityKind(51);
  static const FORESTNPC = const EntityKind(52);
  static const DESERTNPC = const EntityKind(53);
  static const LAVANPC = const EntityKind(54);
  static const CODER = const EntityKind(55);
  
  // Weapons
  static const SWORD1 = const EntityKind(60);
  static const SWORD2 = const EntityKind(61);
  static const REDSWORD = const EntityKind(62);
  static const GOLDENSWORD = const EntityKind(63);
  static const MORNINGSTAR = const EntityKind(64);
  static const AXE = const EntityKind(65);
  static const BLUESWORD = const EntityKind(66);

  // Spells
  static const FROSTNOVA = const EntityKind(100);
  static const FROSTBOLT = const EntityKind(101);
  static const ICEBARRIER = const EntityKind(102);
  static const FIREBALL = const EntityKind(103);
  static const BLINK = const EntityKind(104);
  static const POLYMORPH = const EntityKind(105);

  static const UNKNOWN = const EntityKind(999);
  static const DEATH = const EntityKind(9999);
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

  static Key get(int index) {
    if (!_keys.containsKey(index)) {
      throw new Exception("Key: unknown entity key '${index}'.");
    }
    return _keys[index];
  }

  static Map<int, Key> _keys = {
    13: Key.ENTER,
    27: Key.ESC,
    38: Key.UP,
    40: Key.DOWN,
    37: Key.LEFT,
    39: Key.RIGHT,
    87: Key.W,
    65: Key.A,
    83: Key.S,
    68: Key.D,
    9: Key.TAB,
    32: Key.SPACE,
    70: Key.F,
    72: Key.H,
    73: Key.I,
    75: Key.K,
    77: Key.M,
    80: Key.P,
    84: Key.T,
    89: Key.Y,
    100: Key.KEYPAD_4,
    102: Key.KEYPAD_6,
    104: Key.KEYPAD_8,
    98: Key.KEYPAD_2,
    191: Key.SLASH
  };
}

class Key {
  final int index;
  const Key(int this.index);

  static const ENTER = const Key(13);
  static const ESC = const Key(27);
  static const UP = const Key(38);
  static const DOWN = const Key(40);
  static const LEFT = const Key(37);
  static const RIGHT = const Key(39);
  static const W = const Key(87);
  static const A = const Key(65);
  static const S = const Key(83);
  static const D = const Key(68);
  static const TAB = const Key(9);
  static const SPACE = const Key(32);
  static const F = const Key(70);
  static const H = const Key(72);
  static const I = const Key(73);
  static const K = const Key(75);
  static const M = const Key(77);
  static const P = const Key(80);
  static const T = const Key(84);
  static const Y = const Key(89);
  static const KEYPAD_4 = const Key(100);
  static const KEYPAD_6 = const Key(102);
  static const KEYPAD_8 = const Key(104);
  static const KEYPAD_2 = const Key(98);
  static const SLASH = const Key(191);
}

class Types {

  static Map<String, List<dynamic>> kinds = {
    "unknown": [EntityKind.UNKNOWN, "unknown"],

    "death": [EntityKind.DEATH, "death"],

    "player": [EntityKind.PLAYER, "player"],

    "rat": [EntityKind.RAT, "mob"],
    "skeleton": [EntityKind.SKELETON , "mob"],
    "goblin": [EntityKind.GOBLIN, "mob"],
    "ogre": [EntityKind.OGRE, "mob"],
    "spectre": [EntityKind.SPECTRE, "mob"],
    "deathknight": [EntityKind.DEATHKNIGHT, "mob"],
    "crab": [EntityKind.CRAB, "mob"],
    "snake": [EntityKind.SNAKE, "mob"],
    "bat": [EntityKind.BAT, "mob"],
    "wizard": [EntityKind.WIZARD, "mob"],
    "eye": [EntityKind.EYE, "mob"],
    "skeleton2": [EntityKind.SKELETON2, "mob"],
    "boss": [EntityKind.BOSS, "mob"],

    "sword1": [EntityKind.SWORD1, "weapon"],
    "sword2": [EntityKind.SWORD2, "weapon"],
    "axe": [EntityKind.AXE, "weapon"],
    "redsword": [EntityKind.REDSWORD, "weapon"],
    "bluesword": [EntityKind.BLUESWORD, "weapon"],
    "goldensword": [EntityKind.GOLDENSWORD, "weapon"],
    "morningstar": [EntityKind.MORNINGSTAR, "weapon"],

    "firefox": [EntityKind.FIREFOX, "armor"],
    "clotharmor": [EntityKind.CLOTHARMOR, "armor"],
    "leatherarmor": [EntityKind.LEATHERARMOR, "armor"],
    "mailarmor": [EntityKind.MAILARMOR, "armor"],
    "platearmor": [EntityKind.PLATEARMOR, "armor"],
    "redarmor": [EntityKind.REDARMOR, "armor"],
    "goldenarmor": [EntityKind.GOLDENARMOR, "armor"],

    "flask": [EntityKind.FLASK, "object"],
    "cake": [EntityKind.CAKE, "object"],
    "burger": [EntityKind.BURGER, "object"],
    "chest": [EntityKind.CHEST, "object"],
    "firepotion": [EntityKind.FIREPOTION, "object"],

    "guard": [EntityKind.GUARD, "npc"],
    "villagegirl": [EntityKind.VILLAGEGIRL, "npc"],
    "villager": [EntityKind.VILLAGER, "npc"],
    "coder": [EntityKind.CODER, "npc"],
    "scientist": [EntityKind.SCIENTIST, "npc"],
    "priest": [EntityKind.PRIEST, "npc"],
    "king": [EntityKind.KING, "npc"],
    "rick": [EntityKind.RICK, "npc"],
    "nyan": [EntityKind.NYAN, "npc"],
    "sorcerer": [EntityKind.SORCERER, "npc"],
    "agent": [EntityKind.AGENT, "npc"],
    "octocat": [EntityKind.OCTOCAT, "npc"],
    "beachnpc": [EntityKind.BEACHNPC, "npc"],
    "forestnpc": [EntityKind.FORESTNPC, "npc"],
    "desertnpc": [EntityKind.DESERTNPC, "npc"],
    "lavanpc": [EntityKind.LAVANPC, "npc"],

    "frostnova": [EntityKind.FROSTNOVA, "spell"],
    "frostbolt": [EntityKind.FROSTBOLT, "spell"],
    "icebarrier": [EntityKind.ICEBARRIER, "spell"],
    "fireball": [EntityKind.FIREBALL, "spell"],
    "blink": [EntityKind.BLINK, "spell"],
    "polymorph": [EntityKind.POLYMORPH, "spell"] 
  };
      
  static var rankedWeapons = [
    EntityKind.SWORD1,
    EntityKind.SWORD2,
    EntityKind.AXE,
    EntityKind.MORNINGSTAR,
    EntityKind.BLUESWORD,
    EntityKind.REDSWORD,
    EntityKind.GOLDENSWORD
  ];

  static var rankedArmors = [
    EntityKind.CLOTHARMOR,
    EntityKind.LEATHERARMOR,
    EntityKind.MAILARMOR,
    EntityKind.PLATEARMOR,
    EntityKind.REDARMOR,
    EntityKind.GOLDENARMOR
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
    return (kind == EntityKind.FLASK);
  }

  static bool isUseOnPickup(kind) {
    return (kind == EntityKind.FIREPOTION);
  }

  static bool isObject(kind) {
    return Types.getType(kind) == "object";
  }

  static bool isChest(kind) {
    return kind == EntityKind.CHEST;
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
    return kind == EntityKind.FLASK 
           || kind == EntityKind.BURGER;
  }

  static bool isExpendableItem(kind) {
    return Types.isHealingItem(kind)
           || kind == EntityKind.FIREPOTION
           || kind == EntityKind.CAKE;
  }

  static String getType(kind) {
    if (kind == null) {
      throw "Undefiend kind given to Types.getType";
    }

    if (kinds.containsKey(Types.getKindAsString(kind))) {
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
    if (kind == null) {
      throw "Null kind given to Types.getKindAsString ${kind}";
    }

    for (final k in kinds.keys) {
      if (k != "getType" && kinds[k][0] == kind) {
        return k;
      }
    }

    throw "Inexistant kind given to Types.getKindAsString ${kind}";
  }

  static void forEachKind(callback) {
    kinds.forEach((String name, List<dynamic> data) {
      callback(data[0], name);
    });
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
    all.remove(EntityKind.SWORD1);
    all.remove(EntityKind.CLOTHARMOR);
    int randIndex = rng.nextInt(all.length).floor();
    
    return all[randIndex];
  }
}
