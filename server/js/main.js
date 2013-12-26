var fs = require('fs'),
  Metrics = require('./metrics');


function main(config) {
  var ws = require("./ws"),
    WorldServer = require("./worldserver"),
    Log = require('log'),
    _ = require('underscore'),
    metrics = config.metrics_enabled ? new Metrics(config) : null;

  worlds = [];

  var server = new ws.MultiVersionWebsocketServer(config.port, config, worlds, metrics);

  lastTotalPlayers = 0;
  checkPopulationInterval = setInterval(function () {
    if (metrics && metrics.isReady) {
      metrics.getTotalPlayers(function (totalPlayers) {
        if (totalPlayers !== lastTotalPlayers) {
          lastTotalPlayers = totalPlayers;
          _.each(worlds, function (world) {
            world.updatePopulation(totalPlayers);
          });
        }
      });
    }
  }, 1000);

  switch (config.debug_level) {
    case "error":
      log = new Log(Log.ERROR);
      break;
    case "debug":
      log = new Log(Log.DEBUG);
      break;
    case "info":
      log = new Log(Log.INFO);
      break;
  };

  log.info("Starting BrowserQuest game server...");

  var onPopulationChange = function () {
    metrics.updatePlayerCounters(worlds, function (totalPlayers) {
      _.each(worlds, function (world) {
        world.updatePopulation(totalPlayers);
      });
    });
    metrics.updateWorldDistribution(getWorldDistribution(worlds));
  };

  _.each(_.range(config.nb_worlds), function (i) {
    var world = new WorldServer('world' + (i + 1), config.nb_players_per_world, server, config.map_filepath);
    worlds.push(world);
    if (metrics) {
      world.on(["PlayerAdded", "PlayerRemoved"], onPopulationChange);
    }
  });

  server.onRequestStatus(function () {
    return JSON.stringify(getWorldDistribution(worlds));
  });

  if (config.metrics_enabled) {
    // initialize all counters to 0 when the server starts
    metrics.on("Ready", onPopulationChange);
  }

  process.on('uncaughtException', function (e) {
    log.error('uncaughtException. Error: ' + e);

    if (e.stack) {
      log.error(e.stack);
    }
  });
}

function getWorldDistribution(worlds) {
  var distribution = [];

  _.each(worlds, function (world) {
    distribution.push(world.playerCount);
  });
  return distribution;
}

function getConfigFile(path, callback) {
  fs.readFile(path, 'utf8', function (err, json_string) {
    if (err) {
      console.error("Could not open config file:", err.path);
      callback(null);
    } else {
      callback(JSON.parse(json_string));
    }
  });
}

var defaultConfigPath = './server/config.json',
  customConfigPath = './server/config_local.json';

process.argv.forEach(function (val, index, array) {
  if (index === 2) {
    customConfigPath = val;
  }
});

getConfigFile(defaultConfigPath, function (defaultConfig) {
  getConfigFile(customConfigPath, function (localConfig) {
    if (localConfig) {
      main(localConfig);
    } else if (defaultConfig) {
      main(defaultConfig);
    } else {
      console.error("Server cannot start without any configuration file.");
      process.exit(1);
    }
  });
});
