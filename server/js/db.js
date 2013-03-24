var cls = require("./lib/class"),
    _ = require("underscore"),
    Log = require('log'),
    mongoose = require("mongoose"),
    Types = require("../../shared/js/gametypes");

// ======= DB SCHEMAS ========

playerSchema = mongoose.Schema({
    name: String,
    x: Number,
    y: Number,
    xp: Number,
    level: Number,
    hp: Number,
    weapon: Number,
    armor: Number
});
Players = mongoose.model('Player', playerSchema);

inventorySchema = mongoose.Schema({
    playerId: String,
    size: Number
});
Inventories = mongoose.model('Inventory', inventorySchema);

itemSchema = mongoose.Schema({
   kind: Number,
   amount: Number,
   inventoryId: String,
   slot: Number,
   barSlot: Number
});
Items = mongoose.model('Item', itemSchema);

skillbarSchema = mongoose.Schema({
   playerId: String,
   size: Number,
   slots: [{kind: Number,
           slot: Number,
           id: String}]
});
Skillbars = mongoose.model('Skillbar', skillbarSchema);

DB = cls.Class.extend({
    init: function() {
        mongoose.connect("mongodb://localhost/browserquest");
        this.connection = mongoose.connection;
        this.connection.on('error', console.error.bind(console, 'connection error:'));

        this.defaultCallback = function(err) {
            if (err) {
                log.debug("Failed executing query. Error: "+err);
            }
        };
    }
});

module.exports = new DB();
