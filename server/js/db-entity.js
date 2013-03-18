var cls = require("./lib/class"),
    Messages = require('./message'),
    Utils = require('./utils');

module.exports = DBEntity = cls.Class.extend({
    init: function(dbEntity) {
        this.data = {};

        this.dbEntity = null;

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

        log.debug("Loaded entity "+this.dbEntity._id+" from DB");
    },

    save: function() {
        if (!this.dbEntity) return; 
        
        var self = this;
      
        self.dbEntity.save(function (err) {
            if (err) {
                log.debug("error saving: " + err);
            } else {
                log.debug("Saved entity "+self.dbEntity._id);
            }
        });

    }
});
