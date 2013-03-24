var cls = require("./lib/class"),
    _ = require("underscore"),
    Messages = require("./message"),
    Utils = require("./utils"),
    Properties = require("./properties"),
    Formulas = require("./formulas"),
    DB = require("./db"),
    DBEntity = require("./db-entity"),
    Types = require("../../shared/js/gametypes");

module.exports = Skillbar = DBEntity.extend({
    init: function(player, callback) {
        this.player = null;
        this.dbEntity = null;

        if (player) {
            this.player = player;
            this.load(player, callback);
        }
    },

    get id() {
        return this.data.id;
    },

    get size() {
        return this.data.size;
    },

    get slots() {
        return this.data.slots;
    },

    swap: function(first, second) {
       var temp = this.skills[first];
       this.skills[first] = this.skills[second];
       this.skills[second] = temp;

       if (this.skills[first]) {
            this.skills[first].slot = first;
       }
       if (this.skills[second]) {
            this.skills[second].slot = second;
       }
    },

    use: function(itemId) {
        // find item with itemId and use it
        for (var i in this.skills) {
            var item = this.skills[i];
            if (item.id == itemId) {
                item.use();
            }
        }
    },

    find: function(itemId) {
        for (var i in this.skills) {
            var item = this.skills[i];
            if (item.id == itemId) {
                return item;
            }
        }

        return null;
    },

    add: function(item) {
    },

    decrease: function(item, amount) {
    },

    remove: function(item) {
    },

    load: function(player, callback) {
        var self = this;
        self.player = player;

        Skillbars.findOne({playerId: self.player.getId()}, function(err, dbEntity){
            if (err) {
                log.debug("Failed fetching skillbar for player id '"+self.player.getId()+"'. Error: "+err);
                return;
            }

            if (dbEntity) {
                log.debug("Found previous skillbar record.");
            } else {
                log.debug("Creating new skillbar record for player id '"+self.player.getId()+"'");
                var dbEntity = new Skillbars({
                    playerId: self.player.getId(),
                    size: 12,
                    slots: []
                });
                dbEntity.save(function(err) {
                    if (err) {
                        log.debug("Failed saving skillbar for player id '"+self.player.getId()+"'. Error: "+err);
                    }
                });
            }

            self.setDBEntity(dbEntity, callback);
        });
    },

    loadFromDB: function(callback) {
        if (!this.dbEntity) return;
        
        var self = this;

        this._super();
       
        if (!self.data) self.data = {};

        Utils.Mixin(self.data, {
            playerId: self.dbEntity.playerId,
            size: self.dbEntity.size,
            slots: self.dbEntity.slots,
            id: self.dbEntity._id
        });

        if (callback) {
            callback();
        }
    },
    
    save: function() {
        if (!this.dbEntity) return;

//        Utils.Mixin(this.dbEntity, this.data);
        this.dbEntity.size = this.data.size;
        for (var i in this.skills) {
            if (this.skills[i]) {
                this.skills[i].save();
            }
        }

        this._super();
    },

    serialize: function() {
        return [this.size, this.slots];
    },
});
