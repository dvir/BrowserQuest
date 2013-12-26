var cls = require("./lib/class"),
  _ = require("underscore");

module.exports = Metrics = Class.extend({
  init: function (config) {
    this.config = config;
    this.client = new(require("memcache")).Client(config.memcached_port, config.memcached_host);
    this.client.connect();

    this.isReady = false;

    this.client.on('connect', function () {
      log.info("Metrics enabled: memcached client connected to " + config.memcached_host + ":" + config.memcached_port);
      this.isReady = true;
      this.trigger("Ready");
    }.bind(this));
  },

  updatePlayerCounters: function (worlds, updatedCallback) {
    var config = this.config;
    var numServers = _.size(config.game_servers);
    var playerCount = _.reduce(worlds, function (sum, world) {
      return sum + world.playerCount;
    }, 0);

    if (!this.isReady) {
      log.error("Memcached client not connected");
      return;
    }

    // Set the number of players on this server
    this.client.set('player_count_' + config.server_name, playerCount, function () {
      var total_players = 0;

      // Recalculate the total number of players and set it
      _.each(config.game_servers, function (server) {
        this.client.get('player_count_' + server.name, function (error, result) {
          var count = result ? parseInt(result) : 0;

          total_players += count;
          numServers -= 1;
          if (numServers === 0) {
            this.client.set('total_players', total_players, function () {
              if (updatedCallback) {
                updatedCallback(total_players);
              }
            });
          }
        }.bind(this));
      }.bind(this));
    }.bind(this));
  },

  updateWorldDistribution: function (worlds) {
    this.client.set('world_distribution_' + this.config.server_name, worlds);
  },

  getOpenWorldCount: function (callback) {
    this.client.get('world_count_' + this.config.server_name, function (error, result) {
      callback(result);
    });
  },

  getTotalPlayers: function (callback) {
    this.client.get('total_players', function (error, result) {
      callback(result);
    });
  }
});
