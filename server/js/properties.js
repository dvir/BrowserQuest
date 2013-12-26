var Types = require("../../shared/js/gametypes");

var Properties = {
  rat: {
    drops: {
      flask: 40,
      burger: 10,
      firepotion: 5
    },
    hp: 25,
    armor: Types.Entities.CLOTHARMOR,
    weapon: Types.Entities.SWORD1
  },

  skeleton: {
    drops: {
      flask: 40,
      mailarmor: 10,
      axe: 20,
      firepotion: 5
    },
    hp: 110,
    armor: Types.Entities.LEATHERARMOR,
    weapon: Types.Entities.SWORD2
  },

  goblin: {
    drops: {
      flask: 50,
      leatherarmor: 20,
      axe: 10,
      firepotion: 5
    },
    hp: 90,
    armor: Types.Entities.LEATHERARMOR,
    weapon: Types.Entities.SWORD1
  },

  ogre: {
    drops: {
      burger: 10,
      flask: 50,
      platearmor: 20,
      morningstar: 20,
      firepotion: 5
    },
    hp: 200,
    armor: Types.Entities.MAILARMOR,
    weapon: Types.Entities.SWORD2
  },

  spectre: {
    drops: {
      flask: 30,
      redarmor: 40,
      redsword: 30,
      firepotion: 5
    },
    hp: 250,
    armor: Types.Entities.LEATHERARMOR,
    weapon: Types.Entities.MORNINGSTAR
  },

  deathknight: {
    drops: {
      burger: 95,
      firepotion: 5
    },
    hp: 250,
    armor: Types.Entities.MAILARMOR,
    weapon: Types.Entities.AXE
  },

  crab: {
    drops: {
      flask: 50,
      axe: 20,
      leatherarmor: 10,
      firepotion: 5
    },
    hp: 60,
    armor: Types.Entities.LEATHERARMOR,
    weapon: Types.Entities.SWORD1
  },

  snake: {
    drops: {
      flask: 50,
      mailarmor: 10,
      morningstar: 10,
      firepotion: 5
    },
    hp: 150,
    armor: Types.Entities.MAILARMOR,
    weapon: Types.Entities.SWORD2
  },

  skeleton2: {
    drops: {
      flask: 60,
      platearmor: 15,
      bluesword: 15,
      firepotion: 5
    },
    hp: 200,
    armor: Types.Entities.MAILARMOR,
    weapon: Types.Entities.AXE
  },

  eye: {
    drops: {
      flask: 50,
      redarmor: 20,
      redsword: 10,
      firepotion: 5
    },
    hp: 200,
    armor: Types.Entities.MAILARMOR,
    weapon: Types.Entities.AXE
  },

  bat: {
    drops: {
      flask: 50,
      axe: 10,
      firepotion: 5
    },
    hp: 80,
    armor: Types.Entities.LEATHERARMOR,
    weapon: Types.Entities.SWORD1
  },

  wizard: {
    drops: {
      flask: 50,
      platearmor: 20,
      firepotion: 5
    },
    hp: 100,
    armor: Types.Entities.LEATHERARMOR,
    weapon: Types.Entities.REDSWORD
  },

  boss: {
    drops: {
      goldensword: 100
    },
    hp: 700,
    armor: Types.Entities.GOLDENARMOR,
    weapon: Types.Entities.GOLDENSWORD
  }
};

Properties.getArmorLevel = function (kind) {
  try {
    if (Types.isMob(kind)) {
      return Properties[Types.getKindAsString(kind)].armor;
    } else {
      return Types.getArmorRank(kind) + 1;
    }
  } catch (e) {
    log.error("No level found for armor: " + Types.getKindAsString(kind));
  }
};

Properties.getWeaponLevel = function (kind) {
  try {
    if (Types.isMob(kind)) {
      return Properties[Types.getKindAsString(kind)].weapon;
    } else {
      return Types.getWeaponRank(kind) + 1;
    }
  } catch (e) {
    log.error("No level found for weapon: " + Types.getKindAsString(kind));
  }
};

Properties.getHitPoints = function (kind) {
  return Properties[Types.getKindAsString(kind)].hp;
};

module.exports = Properties;
