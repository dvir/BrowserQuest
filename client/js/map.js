define(['jquery', 'area'], function ($, Area) {

  var Map = Class.extend({
    init: function (loadMultiTilesheets, game) {
      this.game = game;
      this.data = [];
      this.isLoaded = false;
      this.tilesetsLoaded = false;
      this.mapLoaded = false;
      this.loadMultiTilesheets = loadMultiTilesheets;

      var useWorker = !(this.game.renderer.mobile || this.game.renderer.tablet);

      this._loadMap(useWorker);
      this._initTilesets();
    },

    _checkReady: function () {
      if (this.tilesetsLoaded && this.mapLoaded) {
        this.isLoaded = true;
        if (this.ready_func) {
          this.ready_func();
        }
      }
    },

    _loadMap: function (useWorker) {
      var filepath = "maps/world_client.json";

      if (useWorker) {
        log.info("Loading map with web worker.");
        var worker = new Worker('js/mapworker.js');
        worker.postMessage(1);

        worker.onmessage = function (event) {
          var map = event.data;
          this._initMap(map);
          this.grid = map.grid;
          this.plateauGrid = map.plateauGrid;
          this.mapLoaded = true;
          this._checkReady();
        }.bind(this);
      } else {
        log.info("Loading map via Ajax.");
        $.get(filepath, function (data) {
          this._initMap(data);
          this._generateCollisionGrid();
          this._generatePlateauGrid();
          this.mapLoaded = true;
          this._checkReady();
        }.bind(this), 'json');
      }
    },

    _initTilesets: function () {
      var tileset1, tileset2, tileset3;

      if (!this.loadMultiTilesheets) {
        this.tilesetCount = 1;
        tileset1 = this._loadTileset('img/1/tilesheet.png');
      } else {
        if (this.game.renderer.mobile || this.game.renderer.tablet) {
          this.tilesetCount = 1;
          tileset2 = this._loadTileset('img/2/tilesheet.png');
        } else {
          this.tilesetCount = 2;
          tileset2 = this._loadTileset('img/2/tilesheet.png');
          tileset3 = this._loadTileset('img/3/tilesheet.png');
        }
      }

      this.tilesets = [tileset1, tileset2, tileset3];
    },

    _initMap: function (map) {
      this.width = map.width;
      this.height = map.height;
      this.tilesize = map.tilesize;
      this.data = map.data;
      this.blocking = map.blocking || [];
      this.plateau = map.plateau || [];
      this.musicAreas = map.musicAreas || [];
      this.collisions = map.collisions;
      this.high = map.high;
      this.animated = map.animated;

      this.doors = this._getDoors(map);
      this.checkpoints = this._getCheckpoints(map);
    },

    _getDoors: function (map) {
      var doors = {};

      _.each(map.doors, function (door) {
        var o;

        switch (door.to) {
          case 'u':
            o = Types.Orientations.UP;
            break;
          case 'd':
            o = Types.Orientations.DOWN;
            break;
          case 'l':
            o = Types.Orientations.LEFT;
            break;
          case 'r':
            o = Types.Orientations.RIGHT;
            break;
          default:
            o = Types.Orientations.DOWN;
        }

        doors[this.GridPositionToTileIndex(door.x, door.y)] = {
          x: door.tx,
          y: door.ty,
          orientation: o,
          cameraX: door.tcx,
          cameraY: door.tcy,
          portal: door.p === 1,
        };
      }.bind(this));

      return doors;
    },

    _loadTileset: function (filepath) {
      var tileset = new Image();

      tileset.src = filepath;

      log.info("Loading tileset: " + filepath);

      tileset.onload = function () {
        if (tileset.width % this.tilesize > 0) {
          throw Error("Tileset size should be a multiple of " + this.tilesize);
        }
        log.info("Map tileset loaded.");

        this.tilesetCount -= 1;
        if (this.tilesetCount === 0) {
          log.debug("All map tilesets loaded.")

          this.tilesetsLoaded = true;
          this._checkReady();
        }
      }.bind(this);

      return tileset;
    },

    ready: function (f) {
      this.ready_func = f;
    },

    tileIndexToGridPosition: function (tileNum) {
      var x = 0,
        y = 0;

      var getX = function (num, w) {
        if (num == 0) {
          return 0;
        }
        return (num % w == 0) ? w - 1 : (num % w) - 1;
      }

      tileNum -= 1;
      x = getX(tileNum + 1, this.width);
      y = Math.floor(tileNum / this.width);

      return {
        x: x,
        y: y
      };
    },

    GridPositionToTileIndex: function (x, y) {
      return (y * this.width) + x + 1;
    },

    isColliding: function (x, y) {
      if (this.isOutOfBounds(x, y) || !this.grid) {
        return false;
      }
      return (this.grid[y][x] === 1);
    },

    isPlateau: function (x, y) {
      if (this.isOutOfBounds(x, y) || !this.plateauGrid) {
        return false;
      }
      return (this.plateauGrid[y][x] === 1);
    },

    _generateCollisionGrid: function () {
      var tileIndex = 0;

      this.grid = [];
      for (var j, i = 0; i < this.height; i++) {
        this.grid[i] = [];
        for (j = 0; j < this.width; j++) {
          this.grid[i][j] = 0;
        }
      }

      _.each(this.collisions, function (tileIndex) {
        var pos = this.tileIndexToGridPosition(tileIndex + 1);
        this.grid[pos.y][pos.x] = 1;
      }.bind(this));

      _.each(this.blocking, function (tileIndex) {
        var pos = this.tileIndexToGridPosition(tileIndex + 1);
        if (this.grid[pos.y] !== undefined) {
          this.grid[pos.y][pos.x] = 1;
        }
      }.bind(this));

      log.info("Collision grid generated.");
    },

    _generatePlateauGrid: function () {
      var tileIndex = 0;

      this.plateauGrid = [];
      for (var j, i = 0; i < this.height; i++) {
        this.plateauGrid[i] = [];
        for (j = 0; j < this.width; j++) {
          if (_.include(this.plateau, tileIndex)) {
            this.plateauGrid[i][j] = 1;
          } else {
            this.plateauGrid[i][j] = 0;
          }
          tileIndex += 1;
        }
      }
      log.info("Plateau grid generated.");
    },

    /**
     * Returns true if the given position is located within the dimensions of the map.
     *
     * @returns {Boolean} Whether the position is out of bounds.
     */
    isOutOfBounds: function (x, y) {
      return isInt(x) && isInt(y) && (x < 0 || x >= this.width || y < 0 || y >= this.height);
    },

    /**
     * Returns true if the given tile id is "high", i.e. above all entities.
     * Used by the renderer to know which tiles to draw after all the entities
     * have been drawn.
     *
     * @param {Number} id The tile id in the tileset
     * @see Renderer.drawHighTiles
     */
    isHighTile: function (id) {
      return _.indexOf(this.high, id + 1) >= 0;
    },

    /**
     * Returns true if the tile is animated. Used by the renderer.
     * @param {Number} id The tile id in the tileset
     */
    isAnimatedTile: function (id) {
      return id + 1 in this.animated;
    },

    /**
     *
     */
    getTileAnimationLength: function (id) {
      return this.animated[id + 1].l;
    },

    /**
     *
     */
    getTileAnimationDelay: function (id) {
      var animProperties = this.animated[id + 1];
      if (animProperties.d) {
        return animProperties.d;
      } else {
        return 100;
      }
    },

    isDoor: function (x, y) {
      return this.doors[this.GridPositionToTileIndex(x, y)] !== undefined;
    },

    getDoorDestination: function (x, y) {
      return this.doors[this.GridPositionToTileIndex(x, y)];
    },

    _getCheckpoints: function (map) {
      var checkpoints = [];
      _.each(map.checkpoints, function (cp) {
        var area = new Area(cp.x, cp.y, cp.w, cp.h);
        area.id = cp.id;
        checkpoints.push(area);
      });
      return checkpoints;
    },

    getCurrentCheckpoint: function (entity) {
      return _.detect(this.checkpoints, function (checkpoint) {
        return checkpoint.contains(entity);
      });
    }
  });

  return Map;
});
