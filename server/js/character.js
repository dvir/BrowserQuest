
var cls = require("./lib/class"),
    Messages = require("./message"),
    Utils = require("./utils"),
    Properties = require("./properties"),
    Types = require("../../shared/js/gametypes");

module.exports = Character = Entity.extend({
    init: function(id, type, kind, x, y) {
        this._super(id, type, kind, x, y);
        
        this.orientation = Utils.randomOrientation();
        this.attackers = {};
        this.target = null;

        this._lastCombat = 0;

        Utils.Mixin(this.data, {
            level: 1,
            hp: 0,
            armor: null,
            weapon: null,
            baseHP: 100
        });

        this.hp = this.maxHP;
    },

    get isInCombat() {
        var COMBAT_COOLDOWN = 5; // 5 seconds
        return ((Date.now() - COMBAT_COOLDOWN*1000) < this._lastCombat);
    },

    combat: function() {
        this._lastCombat = Date.now();
    },
   
    set level(level) {
        this.data.level = level;
        this.isDirty = true;
        this.save();
    },

    get level() {
        return this.data.level;
    },

    get baseHP() {
        return this.data.baseHP;
    },

    set baseHP(hp) {
        this.data.baseHP = hp;
    },

    set hp(hp) {
        this.data.hp = Math.max(0, Math.min(this.maxHP, hp));
        this.isDirty = true;
        this.save();
    },

    get hp() {
        return this.data.hp;
    },

    get maxHP() {
        return this.baseHP + ((this.level - 1) * 20);
    },

    get armor() {
        return this.data.armor;
    },

    set armor(armor) {
        this.data.armor = armor;
        this.isDirty = true;
        this.save();
    },

    get weapon() {
        return this.data.weapon;
    },

    set weapon(weapon) {
        this.data.weapon = weapon;
        this.isDirty = true;
        this.save();
    },

    get armorLevel() {
        return Properties.getArmorLevel(this.armor);
    },

    get weaponLevel() {
        return Properties.getWeaponLevel(this.weapon);
    },

    getState: function() {
        var basestate = this._super(),
            state = [this.hp, this.maxHP, this.orientation, this.target];
        
        return basestate.concat(state);
    },
    
    resetHitPoints: function(maxHitPoints) {
        this.hp = maxHitPoints;
        this.maxHP = maxHitPoints;
    },
    
    regenHealthBy: function(value) {
        var hp = this.hp,
            max = this.maxHP;

        this.hp = Math.min(hp + value, max);
    },
    
    hasFullHealth: function() {
        return this.hp === this.maxHP;
    },
    
    setTarget: function(entity) {
        this.target = entity.id;
    },
    
    clearTarget: function() {
        this.target = null;
    },
    
    hasTarget: function() {
        return this.target !== null;
    },
    
    attack: function() {
        return new Messages.Attack(this.id, this.target);
    },
    
    health: function() {
        return new Messages.Health(this, false);
    },
    
    regen: function() {
        return new Messages.Health(this, true);
    },
    
    addAttacker: function(entity) {
        if(entity) {
            this.attackers[entity.id] = entity;
        }
    },
    
    removeAttacker: function(entity) {
        if(entity && entity.id in this.attackers) {
            delete this.attackers[entity.id];
            log.debug(this.id +" REMOVED ATTACKER "+ entity.id);
        }
    },
    
    forEachAttacker: function(callback) {
        for(var id in this.attackers) {
            callback(this.attackers[id]);
        }
    },

    loadFromDB: function() {
        if (!this.dbEntity) return;
        
        this._super();
    },

    save: function() {
        if (!this.dbEntity) return;

        this._super();
    }
});
