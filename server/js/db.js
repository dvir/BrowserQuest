var cls = require("./lib/class"),
  _ = require("underscore"),
  Log = require('log'),
  mongoose = require("mongoose"),
  Types = require("../../shared/js/gametypes");

// ======= DB SCHEMAS ========

playerSchema = mongoose.Schema({
  online: {type: Boolean, default: false},
  name: String,
  x: Number,
  y: Number,
  xp: {type: Number, default: 0},
  level: {type: Number, default: 1},
  hp: {type: Number, default: 0},
  weapon: Number,
  armor: Number,
  guild: {type: mongoose.Schema.ObjectId, ref: 'Guild'}
});
Players = mongoose.model('Player', playerSchema);

var guildMemberSchema = mongoose.Schema({   
  player: {type: mongoose.Schema.ObjectId, ref: 'Player'},
  rank: {type: Number, default: 1}
});
GuildMember = mongoose.model('GuildMember', guildMemberSchema);

var findMemberByPlayer = function(members, player) {
  var playerEntity = player.getDBEntity();
  var result = null;
  members.forEach(function (member) {
    if (member.player.equals(playerEntity._id)) {
      result = member;
    }
  });

  return result;
};

var guildSchema = mongoose.Schema({
  name: String,
  members: [guildMemberSchema]
});

guildSchema.methods.broadcast = function(server, message) {
  this.members.forEach(function (member) {
    var player = server.getPlayerByDBID(member.player);
    // only try to send for online players
    if (player) {
      player.send(message);
    }
  });
};

guildSchema.methods.isMember = function(player) {
  return (null != findMemberByPlayer(this.members, player));
};

guildSchema.methods.isLeader = function(player) {
  var member = findMemberByPlayer(this.members, player);
  if (!member) {
    return false;
  }

  return member.rank == 0;
};

guildSchema.methods.getCapacity = function() {
  return 10;
};

guildSchema.methods.getMembersCount = function() {
  return this.members.toObject().length;
};

guildSchema.methods.getMembers = function() {
  return this.members.toObject();
};

guildSchema.methods.getMembersPlayers = function(callback) {
  Guilds
  .findById({_id: this._id}) 
  .populate("members.player")
  .exec(function(err, guild) {
    if (err) {
      log.error("Guild.getMembersPlayers - failed populating guild members: " + err);
      return;
    }

    if (callback) {
      callback(_.filter(guild.members, function(v, k) { return v != {}; }));
    }
  }.bind(this));
};

guildSchema.methods.isFull = function() {
  return this.getCapacity() == this.getMembersCount();
};

guildSchema.methods.addMember = function(player, callback) {
  log.debug("addMember - looking for existing membership");
  var member = findMemberByPlayer(this.members, player);
  if (member) {
    // player is already in the guild
    return;
  }
  log.debug("addMember - not yet in the guild");

  var playerEntity = player.getDBEntity();
  var guildMember = new GuildMember;
  guildMember.player = playerEntity._id;
  log.debug("Creating new guild member");

  this.members.push(guildMember);
  this.save(function (err) {
    if (err) {
      log.debug("Failed saving guild with new guild member - Guilds.addMember: " + err);
      return;
    }

    log.debug("Saved new guild member");

    if (callback) {
      callback(guildMember, this);
    }
  }.bind(this));
};

guildSchema.methods.removeMember = function(player, callback) {
  log.debug("removeMember - looking for existing membership");
  var member = findMemberByPlayer(this.members, player);
  if (!member) {
    // player is not in the guild
    log.error("removeMember - player is not in the guild");
    return;
  }

  member.remove();

  log.debug("removeMember - saving guild after removal of member");
  this.save(function (err) {
    if (err) {
      log.debug("Failed saving guild after removing member - Guilds.removeMember: " + err);
      return;
    }

    log.debug("removeMember - removed member from guild");

    if (callback) {
      callback(this);
    }
  }.bind(this));
};

guildSchema.methods.setLeader = function(player, callback) {
  var member = findMemberByPlayer(this.members, player);
  if (!member) {
    // player is not in the guild
    // and the leader must be a member of the guild
    log.debug("Guild.setLeader - player is not in the guild");
    return;
  }

  member.rank = 0;
  this.save(function (err) {
    if (err) {
      log.error("Guild.setLeader - Failed saving member after rank change: " + err);
    }
    if (callback) {
      callback();
    }
  }.bind(this));
};

guildSchema.methods.getRank = function(player, callback) {
  var member = findMemberByPlayer(this.members, player);
  if (!member) {
    // player is not in the guild
    return;
  }

  return member.rank;
};

guildSchema.statics.create = function (name, leader, callback) {
  var guild = new Guilds;
  guild.name = name;
  log.debug("Creating a new guild");
  guild.addMember(leader, function() {
    log.debug("Added leader to the new guild");
    guild.setLeader(leader, function () {
      log.debug("Set the first member as the leader");
      guild.save(function (err) {
        if (err) {
          log.debug("error creating guild - Guilds.create: " + err);
          return;
        }

        log.debug("Saved the new guild");

        if (callback) {
          callback(guild);
        }
      });
    });
  });
};

guildSchema.statics.isAvailableName = function (name, callback) {
  Guilds.count({name: name}, function (err, count) {
    if (err) {
      log.debug("error on count of guilds - Guilds.isAvailableName: " + err);
      return;
    }

    callback(count == 0);
  });
};

guildSchema.statics.nameMaxLength = function () {
  return 24;
};

guildSchema.methods.kick = function(kicker, player, callback) {
  var member = findMemberByPlayer(this.members, player);
  if (!member) {
    // player wasn't in the kicker's guild
    return;
  }

  member.remove();

  this.save(function() {
    // removed player from the guild                 
    if (callback) {
      callback(this);
    }
  }.bind(this));
};

Guilds = mongoose.model('Guild', guildSchema);

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
  slots: [{
    kind: Number,
    slot: Number,
    id: String
  }]
});
Skillbars = mongoose.model('Skillbar', skillbarSchema);

DB = cls.Class.extend({
  init: function () {
    mongoose.connect("mongodb://localhost/browserquest");
    this.connection = mongoose.connection;
    this.connection.on('error', console.error.bind(console, 'connection error:'));

    this.defaultCallback = function (err) {
      if (err) {
        log.debug("Failed executing query. Error: " + err);
      }
    };
  }
});

module.exports = new DB();
