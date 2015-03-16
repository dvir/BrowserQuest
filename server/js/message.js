var cls = require("./lib/class"),
  _ = require("underscore"),
  Utils = require("./utils"),
  Types = require("../../shared/js/gametypes");

var Messages = {};
module.exports = Messages;

var Message = cls.Class.extend({});

Messages.Spawn = Message.extend({
  init: function (entity) {
    this.entity = entity;
  },
  serialize: function () {
    var spawn = [Types.Messages.SPAWN];
    return spawn.concat(this.entity.getState());
  }
});

Messages.Despawn = Message.extend({
  init: function (entityId) {
    this.entityId = entityId;
  },
  serialize: function () {
    return [Types.Messages.DESPAWN, this.entityId];
  }
});

Messages.Move = Message.extend({
  init: function (entity) {
    this.entity = entity;
  },
  serialize: function () {
    return [Types.Messages.MOVE,
      this.entity.id,
      this.entity.x,
      this.entity.y];
  }
});

Messages.LootMove = Message.extend({
  init: function (entity, item) {
    this.entity = entity;
    this.item = item;
  },
  serialize: function () {
    return [Types.Messages.LOOTMOVE,
      this.entity.id,
      this.item.id];
  }
});

Messages.Loot = Message.extend({
  init: function (item) {
    this.item = item;
  },
  serialize: function () {
    return [Types.Messages.LOOT,
      this.item.id];
  }
});

Messages.Attack = Message.extend({
  init: function (attackerId, targetId) {
    this.attackerId = attackerId;
    this.targetId = targetId;
  },
  serialize: function () {
    return [Types.Messages.ATTACK,
      this.attackerId,
      this.targetId];
  }
});

Messages.EquipItem = Message.extend({
  init: function (player, itemKind) {
    this.playerId = player.id;
    this.itemKind = itemKind;
  },
  serialize: function () {
    return [Types.Messages.EQUIP,
      this.playerId,
      this.itemKind];
  }
});

Messages.Drop = Message.extend({
  init: function (entity, item) {
    this.entity = entity;
    this.item = item;
  },
  serialize: function () {
    var drop = [Types.Messages.DROP,
      this.entity.id,
      this.item.id,
      this.item.kind,
      _.pluck(this.entity.hatelist, "id")
    ];

    var pos = null;
    if (this.entity instanceof Player) {
      pos = {
        x: this.entity.x,
        y: this.entity.y
      };
    }
    drop.push(pos);
    return drop;
  }
});

Messages.Chat = Message.extend({
  init: function (player, message, channel) {
    this.playerId = player.id;
    this.message = message;
    this.channel = channel;

    // we are also sending the player name in case the receiving player
    // isn't aware of its existence through player id.
    // this allows us to receive chat messages even if the players are at
    // different edges of the world, without sending unnecessary entity data.
    this.playerName = player.name;
  },
  serialize: function () {
    return [Types.Messages.CHAT,
      this.playerId,
      this.message,
      this.channel,
      this.playerName];
  }
});

Messages.Teleport = Message.extend({
  init: function (entity) {
    this.entity = entity;
  },
  serialize: function () {
    return [Types.Messages.TELEPORT,
      this.entity.id,
      this.entity.x,
      this.entity.y];
  }
});

Messages.Damage = Message.extend({
  init: function (entity, points, attacker) {
    this.entity = entity;
    this.points = points;
    this.attacker = attacker;
  },
  serialize: function () {
    return [Types.Messages.DAMAGE,
      this.entity.id,
      this.points,
      this.attacker.id];
  }
});

Messages.Health = Message.extend({
  init: function (entity, isRegen) {
    this.entity = entity;
    this.isRegen = isRegen;
  },
  serialize: function () {
    var health = [Types.Messages.HEALTH,
      this.entity.id,
      this.entity.hp,
      this.entity.maxHP,
      this.isRegen ? 1 : 0
    ];

    return health;
  }
});
Messages.Population = Message.extend({
  init: function (world, total) {
    this.world = world;
    this.total = total;
  },
  serialize: function () {
    return [Types.Messages.POPULATION,
      this.world,
      this.total];
  }
});

Messages.Level = Message.extend({
  init: function (level) {
    this.level = level;
  },
  serialize: function () {
    return [Types.Messages.LEVEL,
      this.level];
  }
});

Messages.XP = Message.extend({
  init: function (xp, maxXP, gainedXP) {
    this.xp = xp;
    this.maxXP = maxXP;
    this.gainedXP = gainedXP | 0;
  },
  serialize: function () {
    return [Types.Messages.XP,
      this.xp,
      this.maxXP,
      this.gainedXP];
  }
});

Messages.Kill = Message.extend({
  init: function (mob) {
    this.mob = mob;
  },
  serialize: function () {
    return [Types.Messages.KILL,
      this.mob.kind];
  }
});

Messages.Defeated = Message.extend({
  init: function (attacker, victim) {
    this.data = {
      attackerName: attacker.name,
      victimName: victim.name,
      x: victim.x,
      y: victim.y
    };
  },
  serialize: function () {
    return [Types.Messages.DEFEATED,
      this.data
    ];
  }
});

Messages.List = Message.extend({
  init: function (ids) {
    this.ids = ids;
  },
  serialize: function () {
    var list = this.ids;

    list.unshift(Types.Messages.LIST);
    return list;
  }
});

Messages.Destroy = Message.extend({
  init: function (entity) {
    this.entity = entity;
  },
  serialize: function () {
    return [Types.Messages.DESTROY,
      this.entity.id];
  }
});

Messages.Blink = Message.extend({
  init: function (item) {
    this.item = item;
  },
  serialize: function () {
    return [Types.Messages.BLINK,
      this.item.id];
  }
});

Messages.Data = Message.extend({
  init: function (data) {
    this.data = data;
  },
  serialize: function () {
    return [Types.Messages.DATA,
      this.data];
  }
});

Messages.Inventory = Message.extend({
  init: function (inventory) {
    this.inventory = inventory;
  },
  serialize: function () {
    return [Types.Messages.INVENTORY,
      this.inventory.serialize()];
  }
});

Messages.PlayerEnter = Message.extend({
  init: function (player) {
    this.player = player;
  },
  serialize: function () {
    return [Types.Messages.PLAYER_ENTER, this.player.getBasicState()];
  }
});

Messages.PlayerUpdate = Message.extend({
  init: function (player) {
    this.player = player;
  },
  serialize: function () {
    return [Types.Messages.PLAYER_UPDATE, this.player.getBasicState()];
  }
});

Messages.PlayerExit = Message.extend({
  init: function (player) {
    this.playerID = player.id;
  },
  serialize: function () {
    return [Types.Messages.PLAYER_EXIT,
      this.playerID];
  }
});

Messages.Players = Message.extend({
  init: function (players) {
    this.players = players;
  },
  serialize: function () {
    var playersData = [];
    for (var i in this.players) {
      playersData.push(this.players[i].getBasicState());
    }
    return [Types.Messages.PLAYERS,
      playersData];
  }
});

Messages.PartyJoin = Message.extend({
  init: function (entity) {
    this.entity = entity;
  },
  serialize: function () {
    return [Types.Messages.PARTY_JOIN,
      this.entity.id];
  }
});

Messages.PartyInitialJoin = Message.extend({
  init: function (party) {
    this.leaderID = party.leader.id;
    this.partyList = party.getMembersIDs();
  },
  serialize: function () {
    return [Types.Messages.PARTY_INITIAL_JOIN,
      this.leaderID,
      this.partyList];
  }
});

Messages.PartyLeave = Message.extend({
  init: function (entity) {
    this.entity = entity;
  },
  serialize: function () {
    return [Types.Messages.PARTY_LEAVE,
      this.entity.id];
  }
});

Messages.PartyLeaderChange = Message.extend({
  init: function (entity) {
    this.entity = entity;
  },
  serialize: function () {
    return [Types.Messages.PARTY_LEADER_CHANGE,
      this.entity.id];
  }
});

Messages.PartyInvite = Message.extend({
  init: function (inviter, invitee) {
    this.inviter = inviter.id;
    this.invitee = invitee.id;
  },
  serialize: function () {
    return [Types.Messages.PARTY_INVITE,
      this.inviter,
      this.invitee];
  }
});

Messages.PartyKick = Message.extend({
  init: function (kicker, kicked) {
    this.kicker = kicker.id;
    this.kicked = kicked.id;
  },
  serialize: function () {
    return [Types.Messages.PARTY_KICK,
      this.kicker,
      this.kicked];
  }
});

Messages.PartyAccept = Message.extend({
  init: function (inviter) {
    this.inviterID = inviter.id;
  },
  serialize: function () {
    return [Types.Messages.PARTY_ACCEPT,
      this.inviterID];
  }
});

Messages.GuildOnline = Message.extend({
  init: function (player) {
    this.playerName = player.name;
  },
  serialize: function () {
    return [Types.Messages.GUILD_ONLINE,
      this.playerName];
  }
});

Messages.GuildOffline = Message.extend({
  init: function (player) {
    this.playerName = player.name;
  },
  serialize: function () {
    return [Types.Messages.GUILD_OFFLINE,
      this.playerName];
  }
});

Messages.GuildQuit = Message.extend({
  init: function (entity) {
    this.entity = entity;
  },
  serialize: function () {
    return [Types.Messages.GUILD_QUIT,
      this.entity.id];
  }
});

Messages.GuildLeaderChange = Message.extend({
  init: function (entity) {
    this.entity = entity;
  },
  serialize: function () {
    return [Types.Messages.GUILD_LEADER_CHANGE,
      this.entity.id];
  }
});

Messages.GuildInvite = Message.extend({
  init: function (inviter, guild) {
    this.inviterName = inviter.name;
    this.guildName = guild.name;
  },
  serialize: function () {
    return [Types.Messages.GUILD_INVITE,
      this.inviterName,
      this.guildName
    ];
  }
});

Messages.GuildJoined = Message.extend({
  init: function (player, guild) {
    this.playerName = player.name;
    this.guildName = guild.name;
  },
  serialize: function () {
    return [Types.Messages.GUILD_JOINED,
      this.playerName,
      this.guildName
    ];
  }
});

Messages.GuildLeft = Message.extend({
  init: function (player, guild) {
    this.playerName = player.name;
    this.guildName = guild.name;
  },
  serialize: function () {
    return [Types.Messages.GUILD_LEFT,
      this.playerName,
      this.guildName
    ];
  }
});

Messages.GuildKick = Message.extend({
  init: function (kicker, kicked) {
    this.kickerName = kicker.name;
    this.kickedName = kicked.name;
  },
  serialize: function () {
    return [Types.Messages.GUILD_KICK,
      this.kickerName,
      this.kickedName];
  }
});

Messages.GuildAccept = Message.extend({
  init: function (inviter) {
    this.inviterID = inviter.id;
  },
  serialize: function () {
    return [Types.Messages.GUILD_ACCEPT,
      this.inviterID];
  }
});

Messages.GuildMembers = Message.extend({
  init: function (members) {
    this.members = [];
    for (var i in members) {
      var member = members[i];
      var player = member.player;
      this.members.push({
        name: player.name, 
        rank: member.rank, 
        online: player.online
      });
    }
  },
  serialize: function () {
    return [Types.Messages.GUILD_MEMBERS,
      this.members];
  }
});

Messages.CommandNotice = Message.extend({
  init: function (notice) {
    this.notice = notice;
  },
  serialize: function () {
    return [Types.Messages.COMMAND_NOTICE,
      this.notice];
  }
});

Messages.CommandError = Message.extend({
  init: function (error) {
    this.error = error;
  },
  serialize: function () {
    return [Types.Messages.COMMAND_ERROR,
      this.error];
  }
});

Messages.Error = Message.extend({
  init: function (error) {
    this.error = error;
  },
  serialize: function () {
    return [Types.Messages.ERROR,
      this.error];
  }
});
