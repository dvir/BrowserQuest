
var Utils = require("./utils");

var Formulas = {};

Formulas.dmg = function(weaponLevel, armorLevel) {
    var dealt = weaponLevel * Utils.randomInt(5, 10),
        absorbed = armorLevel * Utils.randomInt(1, 3),
        dmg = dealt - absorbed;
    
    if(dmg <= 0) {
        return Utils.randomInt(0, 3);
    } else {
        return dmg;
    }
};

Formulas.hp = function(armorLevel) {
    var hp = 80 + ((armorLevel - 1) * 30);
    return hp;
};

/**
 * Give 5% of the total xp needed, but reduce 1/8 of it for each level of diff
 * between the attacker and the victim. (give no xp for 8 or more level diff)
 * Also, give 1/8 for each level of positive diff (attacker's level is lower
 * than the victim's)
 */
Formulas.xp = function(attacker, victim) {
    var baseAmount = attacker.maxXP * 0.05;
    var maxLevelDiff = 8;
    var xp = Math.ceil(Math.max(0, (baseAmount - (attacker.level - victim.level) * (baseAmount / maxLevelDiff))));
    return xp;
};

if(!(typeof exports === 'undefined')) {
    module.exports = Formulas;
}
