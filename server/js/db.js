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
   inventoryId: String
});
Items = mongoose.model('Item', itemSchema);

DB = cls.Class.extend({
    init: function() {
        mongoose.connect("mongodb://localhost/browserquest");
        this.connection = mongoose.connection;
        this.connection.on('error', console.error.bind(console, 'connection error:'));
    }
});

module.exports = new DB();
