
var Utils = require("./utils");

var Formulas = {};

Formulas.dmg = function(weaponLevel, armorLevel) {
    var dealt = weaponLevel * Utils.randomInt(5, 10),
        absorbed = armorLevel * Utils.randomInt(1, 3),
        dmg =  dealt - absorbed;
    
    //console.log("abs: "+absorbed+"   dealt: "+ dealt+"   dmg: "+ (dealt - absorbed));
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
 * Give 1% of the total xp needed, but reduce 1/8% of it for each level of diff
 * between the attacker and the victim.
 * Also, give 1/8% for each level of positive diff (attacker's level is lower
 * than the victim's)
 */
Formulas.xp = function(attacker, victim) {
    var xp = Math.ceil(Math.max(0, ((attacker.getMaxXP() * 0.01) - (attacker.getLevel() - victim.getLevel()) * (attacker.getMaxXP() * 0.00125)))) + 60;
    return xp;
};

if(!(typeof exports === 'undefined')) {
    module.exports = Formulas;
}
