
Types = {
    Messages: {
        HELLO: 0,
        WELCOME: 1,
        SPAWN: 2,
        DESPAWN: 3,
        MOVE: 4,
        LOOTMOVE: 5,
        AGGRO: 6,
        ATTACK: 7,
        HIT: 8,
        HURT: 9,
        HEALTH: 10,
        CHAT: 11,
        LOOT: 12,
        EQUIP: 13,
        DROP: 14,
        TELEPORT: 15,
        DAMAGE: 16,
        POPULATION: 17,
        KILL: 18,
        LIST: 19,
        WHO: 20,
        ZONE: 21,
        DESTROY: 22,
        BLINK: 24,
        OPEN: 25,
        CHECK: 26,
        XP: 27,
        LEVEL: 28,
        DATA: 29,
        INVENTORY: 30,
        INVENTORYITEM: 31,
        INVENTORYSWAP: 32,
        USE: 33,
        USEITEM: 34,
        USESPELL: 35,
        SKILLBAR: 36,
        THROWITEM: 37,
        RESURRECT: 38,
        PLAYER_ENTER: 39,
        PLAYER_EXIT: 40,
        PLAYERS: 41,
        PARTY_JOIN: 42,
        PARTY_INITIAL_JOIN: 43,
        PARTY_LEAVE: 44,
        PARTY_INVITE: 45,
        PARTY_KICK: 46,
        PARTY_LEADER_CHANGE: 47,
        PARTY_ACCEPT: 48,
        GUILD_JOIN: 49,
        GUILD_ONLINE: 50,
        GUILD_QUIT: 51,
        GUILD_INVITE: 52,
        GUILD_KICK: 53,
        GUILD_LEADER_CHANGE: 54,
        GUILD_ACCEPT: 55,
        GUILD_CREATE: 56,
        GUILD_MEMBERS: 57,
        GUILD_JOINED: 58,
        GUILD_LEFT: 59,
        GUILD_ONLINE: 60,
        GUILD_OFFLINE: 61,
        PLAYER_UPDATE: 62,
        DEFEATED: 63,

        COMMAND_NOTICE: 9998,
        COMMAND_ERROR: 9999,
        ERROR: 10000
    },
    
    Entities: {
        UNKNOWN: 999,

        PLAYER: 1,
        
        // Mobs
        RAT: 2,
        SKELETON: 3,
        GOBLIN: 4,
        OGRE: 5,
        SPECTRE: 6,
        CRAB: 7,
        BAT: 8,
        WIZARD: 9,
        EYE: 10,
        SNAKE: 11,
        SKELETON2: 12,
        BOSS: 13,
        DEATHKNIGHT: 14,
        
        // Armors
        FIREFOX: 20,
        CLOTHARMOR: 21,
        LEATHERARMOR: 22,
        MAILARMOR: 23,
        PLATEARMOR: 24,
        REDARMOR: 25,
        GOLDENARMOR: 26,
        
        // Objects
        FLASK: 35,
        BURGER: 36,
        CHEST: 37,
        FIREPOTION: 38,
        CAKE: 39,
        
        // NPCs
        GUARD: 40,
        KING: 41,
        OCTOCAT: 42,
        VILLAGEGIRL: 43,
        VILLAGER: 44,
        PRIEST: 45,
        SCIENTIST: 46,
        AGENT: 47,
        RICK: 48,
        NYAN: 49,
        SORCERER: 50,
        BEACHNPC: 51,
        FORESTNPC: 52,
        DESERTNPC: 53,
        LAVANPC: 54,
        CODER: 55,
        
        // Weapons
        SWORD1: 60,
        SWORD2: 61,
        REDSWORD: 62,
        GOLDENSWORD: 63,
        MORNINGSTAR: 64,
        AXE: 65,
        BLUESWORD: 66,

        // Spells
        FROSTNOVA: 100,
        FROSTBOLT: 101,
        ICEBARRIER: 102,
        FIREBALL: 103,
        BLINK: 104,
        POLYMORPH: 105,

        // using this so I won't have to mess with ending commas
        DEATH: 9999
    },
    
    Orientations: {
        UP: 1,
        DOWN: 2,
        LEFT: 3,
        RIGHT: 4
    },

    Keys: {
        ENTER: 13,
        ESC: 27,
        UP: 38,
        DOWN: 40,
        LEFT: 37,
        RIGHT: 39,
        W: 87,
        A: 65,
        S: 83,
        D: 68,
        TAB: 9,
        SPACE: 32,
        F: 70,
        H: 72,
        I: 73,
        K: 75,
        M: 77,
        P: 80,
        T: 84,
        Y: 89,
        KEYPAD_4: 100,
        KEYPAD_6: 102,
        KEYPAD_8: 104,
        KEYPAD_2: 98,
        SLASH: 191
    }
};

var kinds = {
    unknown: [Types.Entities.UNKNOWN, "unknown"],

    death: [Types.Entities.DEATH, "death"],

    player: [Types.Entities.PLAYER, "player"],
    
    rat: [Types.Entities.RAT, "mob"],
    skeleton: [Types.Entities.SKELETON , "mob"],
    goblin: [Types.Entities.GOBLIN, "mob"],
    ogre: [Types.Entities.OGRE, "mob"],
    spectre: [Types.Entities.SPECTRE, "mob"],
    deathknight: [Types.Entities.DEATHKNIGHT, "mob"],
    crab: [Types.Entities.CRAB, "mob"],
    snake: [Types.Entities.SNAKE, "mob"],
    bat: [Types.Entities.BAT, "mob"],
    wizard: [Types.Entities.WIZARD, "mob"],
    eye: [Types.Entities.EYE, "mob"],
    skeleton2: [Types.Entities.SKELETON2, "mob"],
    boss: [Types.Entities.BOSS, "mob"],

    sword1: [Types.Entities.SWORD1, "weapon"],
    sword2: [Types.Entities.SWORD2, "weapon"],
    axe: [Types.Entities.AXE, "weapon"],
    redsword: [Types.Entities.REDSWORD, "weapon"],
    bluesword: [Types.Entities.BLUESWORD, "weapon"],
    goldensword: [Types.Entities.GOLDENSWORD, "weapon"],
    morningstar: [Types.Entities.MORNINGSTAR, "weapon"],
    
    firefox: [Types.Entities.FIREFOX, "armor"],
    clotharmor: [Types.Entities.CLOTHARMOR, "armor"],
    leatherarmor: [Types.Entities.LEATHERARMOR, "armor"],
    mailarmor: [Types.Entities.MAILARMOR, "armor"],
    platearmor: [Types.Entities.PLATEARMOR, "armor"],
    redarmor: [Types.Entities.REDARMOR, "armor"],
    goldenarmor: [Types.Entities.GOLDENARMOR, "armor"],

    flask: [Types.Entities.FLASK, "object"],
    cake: [Types.Entities.CAKE, "object"],
    burger: [Types.Entities.BURGER, "object"],
    chest: [Types.Entities.CHEST, "object"],
    firepotion: [Types.Entities.FIREPOTION, "object"],

    guard: [Types.Entities.GUARD, "npc"],
    villagegirl: [Types.Entities.VILLAGEGIRL, "npc"],
    villager: [Types.Entities.VILLAGER, "npc"],
    coder: [Types.Entities.CODER, "npc"],
    scientist: [Types.Entities.SCIENTIST, "npc"],
    priest: [Types.Entities.PRIEST, "npc"],
    king: [Types.Entities.KING, "npc"],
    rick: [Types.Entities.RICK, "npc"],
    nyan: [Types.Entities.NYAN, "npc"],
    sorcerer: [Types.Entities.SORCERER, "npc"],
    agent: [Types.Entities.AGENT, "npc"],
    octocat: [Types.Entities.OCTOCAT, "npc"],
    beachnpc: [Types.Entities.BEACHNPC, "npc"],
    forestnpc: [Types.Entities.FORESTNPC, "npc"],
    desertnpc: [Types.Entities.DESERTNPC, "npc"],
    lavanpc: [Types.Entities.LAVANPC, "npc"],

    frostnova: [Types.Entities.FROSTNOVA, "spell"],
    frostbolt: [Types.Entities.FROSTBOLT, "spell"],
    icebarrier: [Types.Entities.ICEBARRIER, "spell"],
    fireball: [Types.Entities.FIREBALL, "spell"],
    blink: [Types.Entities.BLINK, "spell"],
    polymorph: [Types.Entities.POLYMORPH, "spell"] 
};
    
Types.rankedWeapons = [
    Types.Entities.SWORD1,
    Types.Entities.SWORD2,
    Types.Entities.AXE,
    Types.Entities.MORNINGSTAR,
    Types.Entities.BLUESWORD,
    Types.Entities.REDSWORD,
    Types.Entities.GOLDENSWORD
];

Types.rankedArmors = [
    Types.Entities.CLOTHARMOR,
    Types.Entities.LEATHERARMOR,
    Types.Entities.MAILARMOR,
    Types.Entities.PLATEARMOR,
    Types.Entities.REDARMOR,
    Types.Entities.GOLDENARMOR
];

Types.getWeaponRank = function(weaponKind) {
    return _.indexOf(Types.rankedWeapons, weaponKind);
};

Types.getArmorRank = function(armorKind) {
    return _.indexOf(Types.rankedArmors, armorKind);
};

Types.itemRankCompare = function(item1, item2) {
    if (Types.isArmor(item1.kind) && Types.isArmor(item2.kind)) {
        return (Types.getArmorRank(item1.kind) > Types.getArmorRank(item2.kind));
    }

    if (Types.isWeapon(item1.kind) && Types.isWeapon(item2.kind)) {
        return (Types.getWeaponRank(item1.kind) > Types.getWeaponRank(item2.kind));
    }

    throw "Cannot compare rank of items not of the same type.";
};

Types.isPlayer = function(kind) {
    return Types.getType(kind) === "player";
};

Types.isMob = function(kind) {
    return Types.getType(kind) === "mob";
};

Types.isNpc = function(kind) {
    return Types.getType(kind) === "npc";
};

Types.isCharacter = function(kind) {
    return Types.isMob(kind) || Types.isNpc(kind) || Types.isPlayer(kind);
};

Types.isArmor = function(kind) {
    return Types.getType(kind) === "armor";
};

Types.isWeapon = function(kind) {
    return Types.getType(kind) === "weapon";
};

Types.isStackable = function(kind) {
    return (kind == Types.Entities.FLASK);
};

Types.isUseOnPickup = function(kind) {
    return (kind == Types.Entities.FIREPOTION);
};

Types.isObject = function(kind) {
    return Types.getType(kind) === "object";
};

Types.isChest = function(kind) {
    return kind === Types.Entities.CHEST;
};

Types.isItem = function(kind) {
    return Types.isWeapon(kind) 
        || Types.isArmor(kind) 
        || (Types.isObject(kind) && !Types.isChest(kind));
};

Types.isSpell = function(kind) {
    return (Types.getType(kind) == "spell");
};

Types.isHealingItem = function(kind) {
    return kind === Types.Entities.FLASK 
        || kind === Types.Entities.BURGER;
};

Types.isExpendableItem = function(kind) {
    return Types.isHealingItem(kind)
        || kind === Types.Entities.FIREPOTION
        || kind === Types.Entities.CAKE;
};

Types.getType = function(kind) {
    if (!kind) {
        throw "Undefiend kind given to Types.getType";
    }

    if (kinds[Types.getKindAsString(kind)]) {
        return kinds[Types.getKindAsString(kind)][1];
    }

    throw "Inexistant kind given to Types.getType ("+kind+")";
};

Types.getKindFromString = function(kind) {
    if(kind in kinds) {
        return kinds[kind][0];
    }
};

Types.getKindAsString = function(kind) {
    if (!kind) {
        return "unknown";
    }

    for(var k in kinds) {
        if(k != "getType" && kinds[k][0] === kind) {
            return k;
        }
    }

    return "unknown";
};

Types.forEachKind = function(callback) {
    for(var k in kinds) {
        callback(kinds[k][0], k);
    }
};

Types.forEachArmor = function(callback) {
    Types.forEachKind(function(kind, kindName) {
        if(Types.isArmor(kind)) {
            callback(kind, kindName);
        }
    });
};

Types.forEachMobOrNpcKind = function(callback) {
    Types.forEachKind(function(kind, kindName) {
        if(Types.isMob(kind) || Types.isNpc(kind)) {
            callback(kind, kindName);
        }
    });
};

Types.forEachArmorKind = function(callback) {
    Types.forEachKind(function(kind, kindName) {
        if(Types.isArmor(kind)) {
            callback(kind, kindName);
        }
    });
};

Types.getOrientationAsString = function(orientation) {
    switch(orientation) {
        case Types.Orientations.LEFT: return "left"; break;
        case Types.Orientations.RIGHT: return "right"; break;
        case Types.Orientations.UP: return "up"; break;
        case Types.Orientations.DOWN: return "down"; break;
    }
};

Types.getRandomItemKind = function(item) {
    var all = _.union(this.rankedWeapons, this.rankedArmors),
        forbidden = [Types.Entities.SWORD1, Types.Entities.CLOTHARMOR],
        itemKinds = _.difference(all, forbidden),
        i = Math.floor(Math.random() * _.size(itemKinds));
    
    return itemKinds[i];
};

Types.getMessageTypeAsString = function(type) {
    var typeName;
    _.each(Types.Messages, function(value, name) {
        if(value === type) {
            typeName = name;
        }
    });
    if(!typeName) {
        typeName = "UNKNOWN";
    }
    return typeName;
};

if(!(typeof exports === 'undefined')) {
    module.exports = Types;
}
