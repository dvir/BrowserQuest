library game;

import 'dart:async';

/*import "app.dart";*/
import "animatedtile.dart";
import "animation.dart";
import "audiomanager.dart";
import "base.dart";
import "bubblemanager.dart";
import "entity.dart";
import "hero.dart";
import "item.dart";
import "pathfinder.dart";
import "player.dart";
import "position.dart";
import "renderer.dart";
import "sprite.dart";
import "transition.dart";
import "updater.dart";
import "../shared/dart/gametypes.dart";
import 'dart:html' as html;
import 'map.dart';
import 'gameclient.dart';
import 'mob.dart';
import 'npc.dart';
import 'chest.dart';
import 'spelleffect.dart';
import 'tile.dart';
import 'camera.dart';
import 'infomanager.dart';
import 'character.dart';

class Game extends Base {

  static int currentTime = 0;

  static String host;
  static String port;
  static String username;

  static List<List<int>> pathingGrid;
  static List<List<Map<int, Entity>>> entityGrid;
  static List<List<Map<int, Entity>>> renderingGrid;
  static List<List<Map<int, Item>>> itemGrid;

  static bool drawTarget = false;
  static bool clearTarget = false;
  static bool debugPathing = false;
  static Camera camera;

  static Animation targetAnimation;
  static Animation sparksAnimation;

  static Map<int, Position> deathpositions;

  static Position mouse;
  static Position selected; // selected grid position
  static Position previousClickPosition;
  static bool selectedCellVisible = false;

  static String targetColor = "rgba(255, 255, 255, 0.5)";
  static bool targetCellVisible = true;

  static Entity hoveringTarget;
  static Player hoveringPlayer;
  static Mob hoveringMob;
  static Npc hoveringNpc;
  static Item hoveringItem;
  static Chest hoveringChest;
  static bool hoveringPlateauTile = false;
  static bool hoveringCollidingTile = false;

  static bool ready = false;
  static bool started = false;
  static bool hasNeverStarted = true;

  static Transition currentZoning;
  static List<Position> zoningQueue;
  static Orientation zoningOrientation;

  static Hero player;
  static String playerName;

  static Map<int, Player> players;
  static Map<String, Player> playersByName;

  static Map<int, Entity> entities;

  static AudioManager audioManager = new AudioManager();
  static BubbleManager bubbleManager;
  static InfoManager infoManager = new InfoManager();
  static html.InputElement chatInput;
  static Pathfinder pathfinder;
  static Renderer renderer;
  static Updater updater;
  static WorldMap map;

  static GameClient client;

  static Map<String, Sprite> sprites;
  static Map<int, Map<String, Sprite>> spriteSets;
  static List<String> spriteNames = ["hand", "sword", "loot", "target", "talk", "sparks", "shadow16", "rat", "skeleton", "skeleton2", "spectre", "boss", "deathknight",
    "ogre", "crab", "snake", "eye", "bat", "goblin", "wizard", "guard", "king", "villagegirl", "villager", "coder", "agent", "rick", "scientist", "nyan", "priest",
    "sorcerer", "octocat", "beachnpc", "forestnpc", "desertnpc", "lavanpc", "clotharmor", "leatherarmor", "mailarmor",
    "platearmor", "redarmor", "goldenarmor", "firefox", "death", "sword1", "axe", "chest",
    "sword2", "redsword", "bluesword", "goldensword", "item-sword2", "item-axe", "item-redsword", "item-bluesword", "item-goldensword", "item-leatherarmor", "item-mailarmor",
    "item-platearmor", "item-redarmor", "item-goldenarmor", "item-flask", "item-cake", "item-burger", "morningstar", "item-morningstar", "item-firepotion",
    "spell-fireball"
  ];

  static List<AnimatedTile> animatedTiles;

  static Map<String, Sprite> cursors;
  static Sprite currentCursor;
  static Orientation currentCursorOrientation;

  static Map<String, Sprite> shadows;

  static void setup(
    html.Element bubbleContainer,
    html.CanvasElement canvas,
    html.CanvasElement backCanvas,
    html.CanvasElement foreCanvas,
    html.Element chatInput
  ) {
    Game.bubbleManager = new BubbleManager(bubbleContainer);
    Game.renderer = new Renderer(canvas, backCanvas, foreCanvas);
    Game.chatInput = chatInput;
  }

  static void tryUnlockingAchievement(String name) {
    // TODO: implement!
  }

  static void addPlayer(Player player) {
    Game.players.putIfAbsent(player.id, () => player);
    Game.playersByName.putIfAbsent(player.name, () => player);
  }

  static void removePlayer(int playerID) {
    Player player = Game.players.remove(playerID);
    if (player != null) {
      Game.playersByName.remove(player.name);
    }
  }

  static Player getPlayerByID(int playerID) {
    return Game.players[playerID];
  }

  static List<Player> getPlayersByIDs(List<int> playerIDs) {
    List<Player> matchingPlayers = new List<Player>();

    playerIDs.forEach((int id) {
      Player player = Game.players[id];
      if (player != null) {
        matchingPlayers.add(player);
      }
    });

    return matchingPlayers;
  }

  static Player getPlayerByName(String name) {
    return Game.playersByName[name];
  }

  static void loadMap() {
    Game.map = new WorldMap(!Game.renderer.upscaledRendering);
    Game.map.on("ready", () {
      html.window.console.info("Map loaded.");

      int tilesetIndex = Game.renderer.upscaledRendering ? 0 : (Game.renderer.scale - 1);
      Game.renderer.tileset = Game.map.tilesets[tilesetIndex];
    });
  }

  static void resurrect() {
    Game.client.sendResurrect();
  }

  static void initShadows() {
    Game.shadows["small"] = Game.sprites["shadow16"];
  }

  static void initCursors() {
    Game.cursors["hand"] = Game.sprites["hand"];
    Game.cursors["sword"] = Game.sprites["sword"];
    Game.cursors["loot"] = Game.sprites["loot"];
    Game.cursors["target"] = Game.sprites["target"];
    Game.cursors["arrow"] = Game.sprites["arrow"];
    Game.cursors["talk"] = Game.sprites["talk"];
  }

  static void initAnimations() {
    Game.targetAnimation = new Animation(Animation.IDLE_DOWN, 4, 0, 16, 16);
    Game.targetAnimation.speed = 50;

    Game.sparksAnimation = new Animation(Animation.IDLE_DOWN, 6, 0, 16, 16);
    Game.sparksAnimation.speed = 120;
  }

  static void initHurtsprites() {
    Types.forEachArmorKind((Entities kind, String kindName) {
      Game.sprites[kindName].createHurtSprite();
    });
  }

  static void initSilhouettes() {
    Types.forEachMobOrNpcKind((Entities kind, String kindName) {
      Game.sprites[kindName].createSilhouette();
    });

    Game.sprites["chest"].createSilhouette();
    Game.sprites["item-cake"].createSilhouette();
  }

  static void loadSprite(String name) {
    if (Game.renderer.upscaledRendering) {
      Game.spriteSets[0][name] = new Sprite.FromJSON(name, 1);
      return;
    }

    Game.spriteSets[1][name] = new Sprite.FromJSON(name, 2);
    if (Game.renderer.mobile || Game.renderer.tablet) {
      Game.spriteSets[2][name] = new Sprite.FromJSON(name, 3);
    }
  }

  static void loadSprites() {
    html.window.console.info("Loading sprites...");
    Game.spriteSets = new Map<int, Map<String, Sprite>>();
    Game.spriteSets[0] = new Map<String, Sprite>();
    Game.spriteSets[1] = new Map<String, Sprite>();
    Game.spriteSets[2] = new Map<String, Sprite>();
    Game.spriteNames.forEach((String name) {
      Game.loadSprite(name);
    });
  }

  static bool hasAllSpritesLoaded() {
    for (Sprite sprite in Game.sprites.values) {
      if (!sprite.isLoaded) {
        return false;
      }
    }

    return true;
  }

  static void setCursor(String name) {
    if (!Game.cursors.containsKey(name)) {
      throw new Exception("No such cursor '${name}'.");
    }

    Game.currentCursor = Game.cursors[name];
  }

  static void updateCursorLogic() {
    if (Game.hoveringCollidingTile && Game.started) {
      Game.targetColor = "rgba(255, 50, 50, 0.5)";
    } else {
      Game.targetColor = "rgba(255, 255, 255, 0.5)";
    }

    Game.hoveringTarget = null;
    Game.targetCellVisible = false;

    if (Game.started) {
      if (Game.hoveringPlayer != null && Game.player.isHostile(Game.hoveringPlayer)) {
        Game.setCursor("sword");
        return;
      }

      if (Game.hoveringMob != null) {
        Game.setCursor("sword");
        return;
      }

      if (Game.hoveringNpc != null) {
        Game.setCursor("talk");
        return;
      }

      if (Game.hoveringItem != null || Game.hoveringChest != null) {
        Game.setCursor("loot");
        Game.targetCellVisible = true;
        return;
      }
    }

    // default cursor
    Game.setCursor("hand");
    Game.targetCellVisible = true;
  }

  static void focusPlayer() {
    Game.renderer.camera.lookAt(Game.player);
  }

  static void addEntity(Entity entity) {
    if (Game.entities.containsKey(entity.id)) {
      throw new Exception("Entity is already added. (id=${entity.id}, kind=${entity.kind})");
    }

    Game.entities.putIfAbsent(entity.id, () => entity);
    Game.registerEntityPosition(entity);

    if ((entity is Item && entity.wasDropped)
        || (Game.renderer.mobile || Game.renderer.tablet)) {
      entity.fadeIn(Game.currentTime);
    }

    if (Game.renderer.mobile || Game.renderer.tablet) {
      entity.on("dirty", () {
        if (Game.camera.isVisible(entity)) {
          entity.dirtyRect = Game.renderer.getEntityBoundingRect(entity);
          Game.checkOtherDirtyRects(entity.dirtyRect, entity, entity.gridX, entity.gridY);
        }
      });
    }
  }

  static Entity getEntityByID(int id) {
    if (!Game.entities.containsKey(id)) {
      throw new Exception("Entity id=${id} doesn't exist.");
    }

    return Game.entities[id];
  }

  static bool entityIdExists(int id) {
    return Game.entities.containsKey(id);
  }

  static void removeAllEntities() {
    for (Entity entity in Game.entities.values) {
      Game.removeEntity(entity);
    }
  }

  static void removeEntity(Entity entity) {
    if (!Game.entities.containsKey(entity.id)) {
      throw new Exception("Cannot remove an unknown entity. (id=${entity.id})");
    }

    Game.unregisterEntityPosition(entity);
    Game.entities.remove(entity.id);
  }

  static void addSpellEffect(SpellEffect spellEffect, int x, int y) {
    spellEffect.setSprite(Game.sprites[spellEffect.getSpriteName()]);
    spellEffect.setGridPosition(x, y);
    spellEffect.setAnimation("idle", 150);
    Game.addEntity(spellEffect);
  }

  static void removeSpellEffect(SpellEffect spellEffect) {
    spellEffect.isRemoved = true;

    Game.removeFromRenderingGrid(spellEffect, spellEffect.gridX, spellEffect.gridY);
    Game.entities.remove(spellEffect.id);
  }

  static void addItem(Item item, int x, int y) {
    item.setSprite(Game.sprites[item.getSpriteName()]);
    item.setGridPosition(x, y);
    item.setAnimation("idle", 150);
    Game.addEntity(item);
  }

  static void removeItem(Item item) {
    item.isRemoved = true;

    Game.removeFromItemGrid(item, item.gridX, item.gridY);
    Game.removeFromRenderingGrid(item, item.gridX, item.gridY);
    Game.entities.remove(item.id);
  }

  static void initPathingGrid() {
    Game.pathingGrid = new List<List<int>>();
    for (var i = 0; i < Game.map.height; i += 1) {
      Game.pathingGrid[i] = new List<int>();
      for (var j = 0; j < Game.map.width; j += 1) {
        Game.pathingGrid[i][j] = Game.map.grid[i][j];
      }
    }

    html.window.console.info("Initialized the pathing grid with static colliding cells.");
  }

  static void initEntityGrid() {
    Game.entityGrid = new List<List<Map<int, Entity>>>();
    for (var i = 0; i < Game.map.height; i += 1) {
      Game.entityGrid[i] = new List<Map<int, Entity>>();
      for (var j = 0; j < Game.map.width; j += 1) {
        Game.entityGrid[i][j] = new Map<int, Entity>();
      }
    }

    html.window.console.info("Initialized the entity grid.");
  }

  static void initRenderingGrid() {
    Game.renderingGrid = new List<List<Map<int, Entity>>>();
    for (var i = 0; i < Game.map.height; i += 1) {
      Game.renderingGrid[i] = new List<Map<int, Entity>>();
      for (var j = 0; j < Game.map.width; j += 1) {
        Game.renderingGrid[i][j] = new Map<int, Entity>();
      }
    }

    html.window.console.info("Initialized the rendering grid.");
  }

  static void initItemGrid() {
    Game.itemGrid = new List<List<Map<int, Item>>>();
    for (var i = 0; i < Game.map.height; i += 1) {
      Game.itemGrid[i] = new List<Map<int, Item>>();
      for (var j = 0; j < Game.map.width; j += 1) {
        Game.itemGrid[i][j] = new Map<int, Item>();
      }
    }

    html.window.console.info("Initialized the item grid.");
  }

  static void initAnimatedTiles() {
    Game.animatedTiles = new List<AnimatedTile>();
    Game.forEachVisibleTile((int id, int index) {
      if (Game.map.isAnimatedTile(id)) {
        Position pos = Game.map.tileIndexToGridPosition(index);
        Tile tile = new AnimatedTile(
          pos.x,
          pos.y,
          id,
          Game.map.getTileAnimationLength(id),
          Game.map.getTileAnimationDelay(id),
          index
        );
        Game.animatedTiles.add(tile);
      }
    }, 1);
  }

  static void addToRenderingGrid(Entity entity, int x, int y) {
    if (!Game.map.isOutOfBounds(x, y)) {
      Game.renderingGrid[y][x].putIfAbsent(entity.id, () => entity);
    }
  }

  static void removeFromRenderingGrid(Entity entity, int x, int y) {
    Game.renderingGrid[y][x].remove(entity.id);
  }

  static void removeFromEntityGrid(Entity entity, int x, int y) {
    Game.entityGrid[y][x].remove(entity.id);
  }

  static void removeFromItemGrid(Item item, int x, int y) {
    Game.itemGrid[y][x].remove(item.id);
  }

  static void removeFromPathingGrid(x, y) {
    Game.pathingGrid[y][x] = 0;
  }

  /**
   * Registers the entity at two adjacent positions on the grid at the same time.
   * This situation is temporary and should only occur when the entity is moving.
   * This is useful for the hit testing algorithm used when hovering entities with the mouse cursor.
   *
   * @param {Entity} entity The moving entity
   */
  static void registerEntityDualPosition(Character entity) {
    Game.entityGrid[entity.gridY][entity.gridX][entity.id] = entity;
    Game.addToRenderingGrid(entity, entity.gridX, entity.gridY);
    if (entity.nextGridX >= 0 && entity.nextGridY >= 0) {
      Game.entityGrid[entity.nextGridY][entity.nextGridX][entity.id] = entity;
      if (!(entity is Player)) {
        // TODO: don't block the grid? remove this if so
//        Game.pathingGrid[entity.nextGridY][entity.nextGridX] = 1;
      }
    }
  }

  /**
   * Clears the position(s) of this entity in the entity grid.
   *
   * @param {Entity} entity The moving entity
   */
  static void unregisterEntityPosition(Character entity) {
    Game.removeFromEntityGrid(entity, entity.gridX, entity.gridY);
    Game.removeFromPathingGrid(entity.gridX, entity.gridY);
    Game.removeFromRenderingGrid(entity, entity.gridX, entity.gridY);

    if (entity.nextGridX >= 0 && entity.nextGridY >= 0) {
      Game.removeFromEntityGrid(entity, entity.nextGridX, entity.nextGridY);
      Game.removeFromPathingGrid(entity.nextGridX, entity.nextGridY);
    }
  }

  static void registerEntityPosition(Entity entity) {
    int x = entity.gridX;
    int y = entity.gridY;

    if (entity is Character || entity is Chest) {
      Game.entityGrid[y][x][entity.id] = entity;
      if (entity is Chest) {
        Game.pathingGrid[y][x] = 1;
      }
    } else if (entity is Item) {
      Game.itemGrid[y][x][entity.id] = entity;
    }

    Game.addToRenderingGrid(entity, x, y);
  }

  static void setServerOptions(String host, String port, String username) {
    Game.host = host;
    Game.port = port;
    Game.username = username;
  }

  static void loadAudio() {
    Game.audioManager = new AudioManager();
  }

  static void initMusicAreas() {
    for (var area in Game.map.musicAreas) {
      Game.audioManager.addArea(area);
    }
  }

  static void run(started_callback) {
    Game.loadSprites();
    Game.setUpdater(new Updater());
    Game.camera = Game.renderer.camera;
    Game.setSpriteScale(Game.renderer.scale);

    // check every 100 milliseconds if all sprites and map has loaded.
    // @TODO: listen for the relevant events instead.
    new Timer.periodic(new Duration(milliseconds: 100), (Timer timer) {
      if (!Game.map.isLoaded || !Game.hasAllSpritesLoaded()) {
        return;
      }

      Game.ready = true;

      html.window.console.debug('All sprites loaded.');

      Game.loadAudio();

      Game.initMusicAreas();
      Game.initAchievements();
      Game.initCursors();
      Game.initAnimations();
      Game.initShadows();
      Game.initHurtSprites();

      if (!Game.renderer.mobile && !Game.renderer.tablet && Game.renderer.upscaledRendering) {
        Game.initSilhouettes();
      }

      Game.initEntityGrid();
      Game.initItemGrid();
      Game.initPathingGrid();
      Game.initRenderingGrid();

      Game.setPathfinder(new Pathfinder(Game.map.width, Game.map.height));

      //this.initPlayer();
      Game.setCursor("hand");

      Game.connect(started_callback);

      timer.cancel();
    });
  }

  static void tick() {
    Game.currentTime = new Date().getTime();

    if (Game.started) {
      Game.updateCursorLogic();
      Game.updater.update();
      Game.renderer.renderFrame();
    }

    if (!Game.isStopped) {
      window.requestAnimationFrame(Game.tick);
    }
  }

  static void start() {
    Game.tick();
    Game.hasNeverStarted = false;

    html.window.console.info("Game loop started.");
  }

  static void stop() {
    Game.isStopped = true;

    html.window.console.info("Game stopped.");
  }
}