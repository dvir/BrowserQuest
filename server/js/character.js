
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

        Utils.Mixin(this.data, {
            level: 1,
            hp: 0,
            armor: null,
            weapon: null
        });
    },
    
    getArmor: function() {
        return this.data.armor;
    },

    equipArmor: function(kind) {
        this.data.armor = kind;
    },

    getArmorLevel: function() {
        return Properties.getArmorLevel(this.data.armor);
    },
   
    getWeapon: function() {
        return this.data.weapon;
    },

    equipWeapon: function(kind) {
        this.data.weapon = kind;
    },

    getWeaponLevel: function() {
        return Properties.getWeaponLevel(this.data.weapon);
    }, 

    setLevel: function(level) {
        this.data.level = level;
        this.save();
    },

    getLevel: function() {
        return this.data.level;
    },

    getHP: function() {
        return this.data.hp;
    },

    setHP: function(hp) {
        this.data.hp = Math.min(this.getMaxHP(), hp);
        this.save();
    },

    getMaxHP: function() {
        return this.getLevel()*80;
    },

    setMaxHP: function(maxHP) {
        this.maxHitPoints = this.getLevel()*80;
    },
    
    getState: function() {
        var basestate = this._getBaseState(),
            state = [];
        
        state.push(this.orientation);
        if(this.target) {
            state.push(this.target);
        }
        
        return basestate.concat(state);
    },
    
    resetHitPoints: function(maxHitPoints) {
        this.setHP(maxHitPoints);
        this.setMaxHP(maxHitPoints);
    },
    
    regenHealthBy: function(value) {
        var hp = this.getHP(),
            max = this.getMaxHP();

        this.setHP(Math.min(hp + value, max));
    },
    
    hasFullHealth: function() {
        return this.getHP() === this.getMaxHP();
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
        return new Messages.Health(this.getHP(), false);
    },
    
    regen: function() {
        return new Messages.Health(this.getHP(), true);
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
