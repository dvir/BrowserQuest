var _ = require('underscore'),
  Types = require("../../shared/js/gametypes");

(function () {
  FormatChecker = Class.extend({
    init: function () {
      this.formats = [];
      this.formats[Types.Messages.HELLO] = ['s'],
      this.formats[Types.Messages.MOVE] = ['n', 'n'],
      this.formats[Types.Messages.LOOTMOVE] = [],
      this.formats[Types.Messages.AGGRO] = ['n'],
      this.formats[Types.Messages.ATTACK] = ['n'],
      this.formats[Types.Messages.HIT] = ['n'],
      this.formats[Types.Messages.HURT] = ['n'],
      this.formats[Types.Messages.CHAT] = ['s', 's'],
      this.formats[Types.Messages.LOOT] = ['n'],
      this.formats[Types.Messages.TELEPORT] = ['n', 'n'],
      this.formats[Types.Messages.ZONE] = [],
      this.formats[Types.Messages.OPEN] = ['n'],
      this.formats[Types.Messages.CHECK] = ['n'],
      this.formats[Types.Messages.INVENTORY] = [],
      this.formats[Types.Messages.INVENTORYITEM] = [],
      this.formats[Types.Messages.INVENTORYSWAP] = ['n', 'n'],
      this.formats[Types.Messages.USEITEM] = ['s'],
      this.formats[Types.Messages.USESPELL] = ['n', 'o', 'o', 'o'],
      this.formats[Types.Messages.SKILLBAR] = ['o'],
      this.formats[Types.Messages.THROWITEM] = [],
      this.formats[Types.Messages.PARTY_JOIN] = ['n'],
      this.formats[Types.Messages.PARTY_INITIAL_JOIN] = ['o'],
      this.formats[Types.Messages.PARTY_LEAVE] = [],
      this.formats[Types.Messages.PARTY_LEADER_CHANGE] = ['n'],
      this.formats[Types.Messages.PARTY_INVITE] = ['n', 'n'],
      this.formats[Types.Messages.PARTY_KICK] = ['n'],
      this.formats[Types.Messages.PARTY_ACCEPT] = ['n'],
      this.formats[Types.Messages.GUILD_JOIN] = ['s'],
      this.formats[Types.Messages.GUILD_ONLINE] = ['o'],
      this.formats[Types.Messages.GUILD_QUIT] = [],
      this.formats[Types.Messages.GUILD_LEADER_CHANGE] = ['s'],
      this.formats[Types.Messages.GUILD_INVITE] = ['s'],
      this.formats[Types.Messages.GUILD_KICK] = ['s'],
      this.formats[Types.Messages.GUILD_ACCEPT] = ['s'],
      this.formats[Types.Messages.GUILD_CREATE] = ['s'],
      this.formats[Types.Messages.GUILD_MEMBERS] = [],
      this.formats[Types.Messages.RESURRECT] = [],
      this.formats[Types.Messages.COMMAND_NOTICE] = ['s'],
      this.formats[Types.Messages.COMMAND_ERROR] = ['s'],
      this.formats[Types.Messages.ERROR] = ['s']
    },

    check: function (msg) {
      var message = msg.slice(0),
        type = message[0],
        format = this.formats[type];

      message.shift();

      if (format) {
        if (format.length == 0) {
          return true;
        }

        if (message.length !== format.length) {
          return false;
        }
        for (var i = 0, n = message.length; i < n; i += 1) {
          if (format[i] === 'n' && !_.isNumber(message[i])) {
            return false;
          }
          if (format[i] === 's' && !_.isString(message[i])) {
            return false;
          }
        }
        return true;
      } else if (type === Types.Messages.WHO) {
        // WHO messages have a variable amount of params, all of which must be numbers.
        return message.length > 0 && _.all(message, function (param) {
          return _.isNumber(param)
        });
      } else {
        log.error("Unknown message type: " + type);
        return false;
      }
    }
  });

  var checker = new FormatChecker;

  exports.check = checker.check.bind(checker);
})();
