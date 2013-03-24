var cls = require("./lib/class"),
    Messages = require('./message'),
    Utils = require('./utils');

module.exports = DBEntity = cls.Class.extend({
    init: function(dbEntity) {
        this.data = {};

        this.dbEntity = null;
        this.isDirty = false;

        if (dbEntity) {
            this.setDBEntity(dbEntity);
        }
    },
    
    setDBEntity: function(dbEntity, callback) {
        this.dbEntity = dbEntity;

        this.loadFromDB(callback);
    },

    loadFromDB: function(callback) {
        if (!this.dbEntity) return;

        if (callback) {
            callback();
        }
    },

    save: function(callback) {
        if (!this.dbEntity || !this.isDirty) return; 
        
        var self = this;
        self.dbEntity.save(function (err) {
            if (err) {
                log.debug("error saving: " + err);
            } else {
                self.isDirty = false;
                if (callback) {
                    callback();
                }
            }
        });

    }
});
