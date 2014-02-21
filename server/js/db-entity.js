var cls = require("./lib/class"),
  Messages = require('./message'),
  Utils = require('./utils');

module.exports = DBEntity = cls.Class.extend({
  init: function (dbEntity) {
    this.data = {};

    this.dbEntity = null;
    this.isDirty = false;

    if (dbEntity) {
      this.setDBEntity(dbEntity);
    }
  },

  getDBEntity: function () {
    if (!this.dbEntity) {
      log.debug("Called getDBEntity for a null dbEntity");
    }
    return this.dbEntity;
  },

  setDBEntity: function (dbEntity, callback) {
    this.dbEntity = dbEntity;

    this.loadFromDB(callback);
  },

  loadFromDB: function (callback) {
    if (!this.dbEntity) return;

    if (callback) {
      callback();
    }
  },

  save: function (isDirty, callback) {
    if (isDirty) {
      this.isDirty = isDirty;
    }
    if (!this.dbEntity || !this.isDirty) return;

    this.dbEntity.save(function (err) {
      if (err) {
        log.debug("error saving: " + err);
        return;
      } 

      this.isDirty = false;
      if (callback) {
        callback();
      }
    }.bind(this));
  }
});
