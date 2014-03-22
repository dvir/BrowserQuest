library worldmap;

import "dart:convert";
import "dart:html";

import "base.dart";
import "checkpoint.dart";
import "door.dart";
import "entity.dart";
import "game.dart";
import "../shared/dart/gametypes.dart";

class WorldMap extends Base {

  bool tilesetsLoaded = false;
  bool mapLoaded = false;
  bool loadMultiTilesheets;
  var map;
  List<List<int>> grid;
  List<List<int>> plateauGrid;
  Map<int, Door> doors = {};
  List<Checkpoint> checkpoints = [];
  List<ImageElement> tilesets = [];
  int tilesetCount;

  WorldMap(bool this.loadMultiTilesheets) {
    bool useWorker = !(Game.renderer.mobile || Game.renderer.tablet);
    this._loadMap(useWorker);
    this._initTilesets();
  }

  int get width => this.map["width"];
  int get height => this.map["height"];
  int get tilesize => this.map["tilesize"];
  get data => this.map["data"];
  get blocking => this.map["blocking"] ? this.map["blocking"] : [];
  get plateau => this.map["plateau"] ? this.map["plateau"] : [];
  get musicAreas => this.map["musicAreas"] ? this.map["musicAreas"] : [];
  get collisions => this.map["collisions"];
  get high => this.map["high"];
  get animated => this.map["animated"];

  bool get isLoaded => (this.tilesetsLoaded && this.mapLoaded);

  void _loadMap(bool useWorker) {
    String filepath = "maps/world_client.json";

    if (useWorker) {
      window.console.info("Loading map with web worker.");
      var worker = new Worker("js/mapworker.js");
      worker.postMessage(1);
      worker.onMessage = (event) {
        var map = event.data;
        this._initMap(map);
        this.grid = map.grid;
        this.plateauGrid = map.plateauGrid;
        this.mapLoaded = true;
        if (this.isLoaded) {
          this.trigger("Ready");
        }
      };
    } else {
      window.console.info("Loading map via Ajax.");
      HttpRequest.getString(filepath).then((String response) {
        var data = JSON.decode(response);
        this._initMap(data);
        this._generateCollisionGrid();
        this._generatePlateauGrid();
        this.mapLoaded = true;
        if (this.isLoaded) {
          this.trigger("Ready");
        }
      }).catchError((Error error) {
        window.console.error("Failed loading map via AJAX. Error: ${error}"); 
      });
    }
  }

  void _initMap(map) {
    this.map = map;

    this.map.doors.forEach((doorData) {
      Orientation o;

      switch (doorData["to"]) {
        case 'u':
          o = Orientation.UP;
          break;
        case 'd':
          o = Orientation.DOWN;
          break;
        case 'l':
          o = Orientation.LEFT;
          break;
        case 'r':
          o = Orientation.RIGHT;
          break;
        default:
          o = Orientation.DOWN;
      }

      Door door = new Door(doorData.tx, doorData.ty, o, doorData.tcx, doorData.tcy, doorData.p == 1);
      doors[this.GridPositionToTileIndex(door.x, door.y)] = door;
    });

    this.map.checkpoints.forEach((cp) {
      Checkpoint checkpoint = new Checkpoint(cp.id, cp.x, cp.y, cp.w, cp.h);
      this.checkpoints.add(checkpoint);
    });
  }

  void _initTilesets() {
    ImageElement tileset1, tileset2, tileset3;

    if (!this.loadMultiTilesheets) {
      this.tilesetCount = 1;
      tileset1 = this._loadTileset('img/1/tilesheet.png');
    } else {
      if (Game.renderer.mobile || Game.renderer.tablet) {
        this.tilesetCount = 1;
        tileset2 = this._loadTileset('img/2/tilesheet.png');
      } else {
        this.tilesetCount = 2;
        tileset2 = this._loadTileset('img/2/tilesheet.png');
        tileset3 = this._loadTileset('img/3/tilesheet.png');
      }
    }

    this.tilesets = [tileset1, tileset2, tileset3];
  }

  ImageElement _loadTileset(String filepath) {
    ImageElement tileset = new ImageElement();
    tileset.src = filepath;

    window.console.info("Loading tileset: ${filepath}");

    tileset.onLoad.listen((e) {
      if (tileset.width % this.tilesize > 0) {
        throw "Tileset size should be a multiple of ${this.tilesize}";
      }
      window.console.info("Map tileset loaded.");

      this.tilesetCount -= 1;
      if (this.tilesetCount == 0) {
        window.console.info("All map tilesets loaded.");

        this.tilesetsLoaded = true;
        if (this.isLoaded) {
          this.trigger("Ready");
        }
      }
    });

    return tileset;
  }

  Map<String, int> tileIndexToGridPosition(int tileNum) {
    int x = 0;
    int y = 0;

    tileNum--;

    if (x != 0) {
      if (((tileNum + 1) % this.width) == 0) {
        x = this.width - 1;
      } else {
        x = ((tileNum + 1) % this.width) - 1;
      }
    }

    y = (tileNum / this.width).floor();

    return {
      "x": x,
      "y": y
    };
  }

  int GridPositionToTileIndex(int x, int y) => (y * this.width) + x + 1;

  bool isColliding(int x, int y) =>
    !this.isOutOfBounds(x, y)
    && this.grid
    && this.grid[y][x] == 1;

  bool isPlateau(int x, int y) =>
    !this.isOutOfBounds(x, y)
    && this.plateauGrid
    && this.plateauGrid[y][x] == 1;

  void _generateCollisionGrid() {
    var tileIndex = 0;

    this.grid = [];
    for (var j, i = 0; i < this.height; i++) {
      this.grid[i] = []..fillRange(0, this.width, 0);
    }

    this.collisions.forEach((int tileIndex) {
      Map<String, int> pos = this.tileIndexToGridPosition(tileIndex + 1);
      this.grid[pos["y"]][pos["x"]] = 1;
    });

    this.blocking.forEach((int tileIndex) {
      Map<String, int> pos = this.tileIndexToGridPosition(tileIndex + 1);
      this.grid[pos["y"]][pos["x"]] = 1;
    });

    window.console.info("Collision grid generated.");
  }

  void _generatePlateauGrid() {
    var tileIndex = 0;

    this.plateauGrid = [];
    for (var j, i = 0; i < this.height; i++) {
      this.plateauGrid[i] = [];
      for (j = 0; j < this.width; j++) {
        this.plateauGrid[i][j] = this.plateau.contains(tileIndex) ? 1 : 0;
        tileIndex++;
      }
    }

    window.console.info("Plateau grid generated.");
  }

  bool isOutOfBounds(int x, int y) =>
    (x < 0 || x >= this.width || y < 0 || y >= this.height);

  /**
   * Returns true if the given tile id is "high", i.e. above all entities.
   * Used by the renderer to know which tiles to draw after all the entities
   * have been drawn.
   *
   * @param {Number} id The tile id in the tileset
   * @see Renderer.drawHighTiles
   */
  bool isHighTile(int id) => this.high.contains(id + 1);

  /**
   * Returns true if the tile is animated. Used by the renderer.
   * @param {Number} id The tile id in the tileset
   */
  bool isAnimatedTile(int id) => this.animated.containsKey(id + 1);

  int getTileAnimationLength(int id) => this.animated[id + 1]["l"];

  int getTileAnimationDelay(id) {
    if (this.animated[id + 1].containsKey("d")) {
      return this.animated[id + 1]["d"];
    }

    return 100;
  }

  bool isDoor(int x, int y) =>
    this.doors.containsKey(this.GridPositionToTileIndex(x, y));

  Door getDoorDestination(int x, int y) => this.doors[this.GridPositionToTileIndex(x, y)];

  Checkpoint getCurrentCheckpoint(Entity entity) {
    for (final checkpoint in this.checkpoints) {
      if (checkpoint.contains(entity)) {
        return checkpoint;
      }
    }

    return null;
  }
}

