
var cls = require("./lib/class"),
    Messages = require('./message'),
    Utils = require('./utils');

module.exports = Entity = cls.Class.extend({
    init: function(id, type, kind, x, y) {
        this.data = {
            name: "unknown",
            x: x,
            y: y
        };

        this.id = parseInt(id);
        this.type = type;
        this.kind = kind;

        this.dbEntity = null;
    },

    get x() {
        return this.data.x;
    },

    get y() {
        return this.data.y;
    },

    set x(x) {
        this.data.x = x;
    },

    set y(y) {
        this.data.y = y;
    },
    
    destroy: function() {

    },
    
    _getBaseState: function() {
        return [
            parseInt(this.id),
            this.kind,
            this.x,
            this.y
        ];
    },
    
    getState: function() {
        return this._getBaseState();
    },
    
    spawn: function() {
        return new Messages.Spawn(this);
    },
    
    despawn: function() {
        return new Messages.Despawn(this.id);
    },
    
    setPosition: function(x, y) {
        this.x = x;
        this.y = y;
    },
    
    getPositionNextTo: function(entity) {
        var pos = null;
        if(entity) {
            pos = {};
            // This is a quick & dirty way to give mobs a random position
            // close to another entity.
            var r = Utils.random(4);
            
            pos.x = entity.x;
            pos.y = entity.y;
            if(r === 0)
                pos.y -= 1;
            if(r === 1)
                pos.y += 1;
            if(r === 2)
                pos.x -= 1;
            if(r === 3)
                pos.x += 1;
        }
        return pos;
    },
    
    setName: function(name) {
        this.data.name = name;
        this.save();
    },

    getName: function() {
        return this.data.name;
    },

    setDBEntity: function(dbEntity) {
        this.dbEntity = dbEntity;

        this.loadFromDB();
    },

    loadFromDB: function() {
        if (!this.dbEntity) return;

        Utils.Mixin(this.data, {
            name: this.dbEntity.name,
            level: this.dbEntity.level,
            hp: this.dbEntity.hp,
            xp: this.dbEntity.xp,
            weapon: this.dbEntity.weapon,
            armor: this.dbEntity.armor,
            x: this.dbEntity.x,
            y: this.dbEntity.y
        });

        log.debug("Loaded entity "+this.dbEntity._id+" from DB");
    },

    save: function() {
        if (!this.dbEntity) return; 
       
//        Utils.Mixin(this.dbEntity, this.data);
        this.dbEntity.xp = this.data.xp;
        this.dbEntity.hp = this.data.hp;
        this.dbEntity.level = this.data.level;
        this.dbEntity.name = this.data.name;
        this.dbEntity.weapon = this.data.weapon;
        this.dbEntity.armor = this.data.armor;
        this.dbEntity.x = this.data.x;
        this.dbEntity.y = this.data.y;

        this.dbEntity.save(function (err) {
            if (err) {
                log.debug("error saving: " + err);
            }
        });
        log.debug("Saved entity "+this.dbEntity._id);
    }
});
