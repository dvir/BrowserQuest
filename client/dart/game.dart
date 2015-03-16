library game;

import 'dart:async';
import 'dart:math';

import "app.dart";
import "animatedtile.dart";
import "animation.dart";
import "audiomanager.dart";
import "base.dart";
import "bubble.dart";
import "bubblemanager.dart";
import "door.dart";
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
import "lib/gametypes.dart";
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
import 'rect.dart';
import 'audio.dart';
import 'checkpoint.dart';

class Game extends Base {

  static Base events = new Base();

  static int currentTime = 0;
  static int lastAnimateTime = 0;

  static String host;
  static int port;
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

  static Map<int, Position> deathpositions = new Map<int, Position>();

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
  static bool isHoveringPlateauTile = false;
  static bool isHoveringCollidingTile = false;
  static Entity lastHoveredEntity;

  static bool ready = false;
  static bool started = false;
  static bool hasNeverStarted = true;

  static Transition currentZoning;
  static List<Position> zoningQueue = [];
  static Orientation zoningOrientation;

  static Hero player;
  static String playerName;

  static Map<int, Player> players = {};
  static Map<String, Player> playersByName = {};

  static Map<int, Entity> entities = {};
  static Map<int, Entity> obsoleteEntities = {};

  static Application app = new Application();
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

  static Map<String, Sprite> cursors = new Map<String, Sprite>();
  static Sprite currentCursor;
  static Orientation currentCursorOrientation;

  static Map<String, Sprite> shadows = new Map<String, Sprite>();

  static Door townPortalDoor = new Door(new Position(36, 210), Orientation.DOWN, new Position(36, 210), true);
  
  static List<Character> get characters => Game.entities.values.where((Entity entity) => entity is Character).toList(); 

  static void setup(
    Application app,
    html.Element bubbleContainer,
    html.CanvasElement canvas,
    html.CanvasElement backCanvas,
    html.CanvasElement foreCanvas,
    html.Element chatInput
  ) {
    Game.app = app;
    Game.bubbleManager = new BubbleManager(bubbleContainer);
    Game.renderer = new Renderer(canvas, backCanvas, foreCanvas);
    Game.chatInput = chatInput;
  }

  static void initAchievements() {
    // TODO: implement
    // possibly create an AchievementsManager
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
    return playerIDs
      .where((int id) => Game.players.containsKey(id))
      .map((int id) => Game.players[id])
      .toList();
  }

  static Player getPlayerByName(String name) {
    return Game.playersByName[name];
  }

  static void loadMap() {
    Game.map = new WorldMap(!Game.renderer.upscaledRendering);
    Game.map.on("Ready", () {
      html.window.console.info("Map loaded.");

      int tilesetIndex = Game.renderer.upscaledRendering ? 0 : (Game.renderer.scale - 1);
      Game.renderer.tileset = Game.map.tilesets[tilesetIndex];
    });
  }

  static void resurrect() {
    Game.client.sendResurrect();
  }

  // depends on setSpriteScale
  static void initShadows() {
    Game.shadows["small"] = Game.sprites["shadow16"];
  }

  // depends on setSpriteScale
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

  static void initHurtSprites() {
    Types.forEachArmorKind((EntityKind kind, String kindName) {
      Game.sprites[kindName].createHurtSprite();
    });
  }

  static void initSilhouettes() {
    Types.forEachMobOrNpcKind((EntityKind kind, String kindName) {
      Game.sprites[kindName].createSilhouette();
    });

    Game.sprites["chest"].createSilhouette();
    Game.sprites["item-cake"].createSilhouette();
  }

  static void loadSprite(String name) {
    html.window.console.debug("-- loading ${name}");

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
        html.window.console.info("Still waiting for ${sprite.name} (${sprite.id})");
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
    if (Game.isHoveringCollidingTile && Game.started) {
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
          Game.checkOtherDirtyRects(entity.dirtyRect, entity, entity.gridPosition);
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

  static List<Entity> getEntitiesByIDs(List<int> entityIDs) {
    return entityIDs
      .where((int id) => Game.entities.containsKey(id))
      .map((int id) => Game.entities[id])
      .toList();
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

  static void addSpellEffect(SpellEffect spellEffect, Position position) {
    spellEffect.setSprite(Game.sprites[spellEffect.getSpriteName()]);
    spellEffect.gridPosition = position;
    spellEffect.setAnimation("idle", 150);
    Game.addEntity(spellEffect);
  }

  static void removeSpellEffect(SpellEffect spellEffect) {
    spellEffect.isRemoved = true;

    Game.removeFromRenderingGrid(spellEffect, spellEffect.gridPosition);
    Game.entities.remove(spellEffect.id);
  }

  static void addItem(Item item, Position position) {
    item.setSprite(Game.sprites[item.getSpriteName()]);
    item.gridPosition = position;
    item.setAnimation("idle", 150);
    Game.addEntity(item);
  }

  static void removeItem(Item item) {
    item.isRemoved = true;

    Game.removeFromItemGrid(item, item.gridPosition);
    Game.removeFromRenderingGrid(item, item.gridPosition);
    Game.entities.remove(item.id);
  }

  static void initPathingGrid() {
    Game.pathingGrid = new List<List<int>>(Game.map.height);
    for (var i = 0; i < Game.map.height; i += 1) {
      Game.pathingGrid[i] = new List<int>(Game.map.width);
      for (var j = 0; j < Game.map.width; j += 1) {
        Game.pathingGrid[i][j] = Game.map.grid[i][j];
      }
    }

    html.window.console.info("Initialized the pathing grid with static colliding cells.");
  }

  static void initEntityGrid() {
    Game.entityGrid = new List<List<Map<int, Entity>>>(Game.map.height);
    for (var i = 0; i < Game.map.height; i += 1) {
      Game.entityGrid[i] = new List<Map<int, Entity>>(Game.map.width);
      for (var j = 0; j < Game.map.width; j += 1) {
        Game.entityGrid[i][j] = new Map<int, Entity>();
      }
    }

    html.window.console.info("Initialized the entity grid.");
  }

  static void initRenderingGrid() {
    Game.renderingGrid = new List<List<Map<int, Entity>>>(Game.map.height);
    for (var i = 0; i < Game.map.height; i += 1) {
      Game.renderingGrid[i] = new List<Map<int, Entity>>(Game.map.width);
      for (var j = 0; j < Game.map.width; j += 1) {
        Game.renderingGrid[i][j] = new Map<int, Entity>();
      }
    }

    html.window.console.info("Initialized the rendering grid.");
  }

  static void initItemGrid() {
    Game.itemGrid = new List<List<Map<int, Item>>>(Game.map.height);
    for (var i = 0; i < Game.map.height; i += 1) {
      Game.itemGrid[i] = new List<Map<int, Item>>(Game.map.width);
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
          pos,
          id,
          Game.map.getTileAnimationLength(id),
          Game.map.getTileAnimationDelay(id),
          index
        );
        Game.animatedTiles.add(tile);
      }
    }, 1);
  }

  static void addToRenderingGrid(Entity entity, Position position) {
    if (!Game.map.isOutOfBounds(position)) {
      Game.renderingGrid[position.y][position.x].putIfAbsent(entity.id, () => entity);
    }
  }

  static void removeFromRenderingGrid(Entity entity, Position position) {
    Game.renderingGrid[position.y][position.x].remove(entity.id);
  }

  static void removeFromEntityGrid(Entity entity, Position position) {
    Game.entityGrid[position.y][position.x].remove(entity.id);
  }

  static void removeFromItemGrid(Item item, Position position) {
    Game.itemGrid[position.y][position.x].remove(item.id);
  }

  static void removeFromPathingGrid(Position position) {
    Game.pathingGrid[position.y][position.x] = 0;
  }

  /**
   * Registers the entity at two adjacent positions on the grid at the same time.
   * This situation is temporary and should only occur when the entity is moving.
   * This is useful for the hit testing algorithm used when hovering entities with the mouse cursor.
   *
   * @param {Entity} entity The moving entity
   */
  static void registerEntityDualPosition(Character entity) {
    Game.entityGrid[entity.gridPosition.y][entity.gridPosition.x][entity.id] = entity;
    Game.addToRenderingGrid(entity, entity.gridPosition);
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
  static void unregisterEntityPosition(Entity entity) {
    Game.removeFromEntityGrid(entity, entity.gridPosition);
    Game.removeFromPathingGrid(entity.gridPosition);
    Game.removeFromRenderingGrid(entity, entity.gridPosition);

    // TODO: I don't like this checks. get rid of them
    if (entity is Character && entity.nextGridX >= 0 && entity.nextGridY >= 0) {
      Game.removeFromEntityGrid(entity, new Position(entity.nextGridX, entity.nextGridY));
      Game.removeFromPathingGrid(new Position(entity.nextGridX, entity.nextGridY));
    }
  }

  static void registerEntityPosition(Entity entity) {
    if (entity is Character || entity is Chest) {
      Game.entityGrid[entity.gridPosition.y][entity.gridPosition.x][entity.id] = entity;
      if (entity is Chest) {
        Game.pathingGrid[entity.gridPosition.y][entity.gridPosition.x] = 1;
      }
    } else if (entity is Item) {
      Game.itemGrid[entity.gridPosition.y][entity.gridPosition.x][entity.id] = entity;
    }

    Game.addToRenderingGrid(entity, entity.gridPosition);
  }

  static void setServerOptions(String host, int port, String username) {
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
    Game.updater = new Updater();
    Game.camera = Game.renderer.camera;
    Game.setSpriteScale(Game.renderer.scale);

    // check every 100 milliseconds if all sprites and map has loaded.
    // @TODO: listen for the relevant events instead.
    new Timer.periodic(new Duration(milliseconds: 500), (Timer timer) {
      if (!Game.map.isLoaded || !Game.hasAllSpritesLoaded()) {
        return;
      }
      timer.cancel();

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

      Game.pathfinder = new Pathfinder(Game.map.width, Game.map.height);

      //this.initPlayer();
      Game.setCursor("hand");

      Game.connect(started_callback);
    });
  }

  static void tick(num time) {
    html.window.requestAnimationFrame(Game.tick);

    num dt = time - Game.lastAnimateTime;

    if (dt < 40) { // limit to 50 fps
      return;
    }

    Game.lastAnimateTime = time;

    if (dt > 200) { // consider only one frame elapsed if update took too long
      dt = 20;
    }

    Game.currentTime += dt;

    if (Game.started) {
      Game.updateCursorLogic();
      Game.updater.update();
      Game.renderer.renderFrame();
    }
  }

  static void start() {
    Game.started = true;
    Game.hasNeverStarted = false;

    Game.tick(0);

    html.window.console.info("Game loop started.");
  }

  static void stop() {
    Game.started = false;

    html.window.console.info("Game stopped.");
  }
  
  static void restart() {
    html.window.console.debug("Beginning restart");

    Game.resurrect();

    // TODO: implement properly
    //this.storage.incrementRevives();

    if (Game.renderer.mobile || Game.renderer.tablet) {
      Game.renderer.clearScreen(Game.renderer.context);
    }

    html.window.console.debug("Finished restart");
  }

  static void updateInventory() {
    Game.app.updateInventory();
  }

  static void updateSkillbar() {
    Game.app.updateSkillbar();
  }

  static void updateBars() {
    updateInventory();
    updateSkillbar();
  }

  static void showNotification(String message) {
    Game.app.showMessage(message);
  }

  static void teleport(Door dest) {
    Game.player.gridPosition = dest.position;
    Game.player.nextGridX = dest.position.x;
    Game.player.nextGridY = dest.position.y;
    Game.player.turnTo(dest.orientation);
    Game.client.sendTeleport(dest.position);

    if (Game.renderer.mobile && dest.cameraPosition != null) {
      Game.camera.gridPosition = dest.cameraPosition;
      Game.resetZone();
    } else {
      if (dest.isPortal) {
        Game.assignBubbleTo(Game.player);
      } else {
        Game.camera.focusEntity(Game.player);
        Game.resetZone();
      }
    }

    bool hadAttackers = Game.player.attackers.length > 0;

    Game.player.forEachAttacker((Character attacker) {
      attacker.disengage();
      attacker.idle();
    });

    Game.updatePlateauMode();

    // TODO: emit an event, i.e "ZoneChange" and check it there
    Game.checkUndergroundAchievement();

    if (Game.renderer.mobile || Game.renderer.tablet) {
      // When rendering with dirty rects, clear the whole screen when entering a do>
      Game.renderer.clearScreen(Game.renderer.context);
    }

    if (dest.isPortal) {
      Game.audioManager.playSound("teleport");
    }

    if (!Game.player.isDead) {
      Game.audioManager.updateMusic();
    }

    if (hadAttackers) {
      Game.tryUnlockingAchievement("COWARD");
    }
  }

  static void activateTownPortal() {
    if (!Game.player.isDead) {
      Game.teleport(Game.townPortalDoor);
    }
  }

  // TODO: original code deleted the position from this array right after
  // fetching it. figure out why and remove that requirement (possibly a
  // timer that deletes it after some time?)
  static Position getDeadMobPosition(int id) {
    return Game.deathpositions[id];
  }

  static void removeObsoleteEntities() {
    Game.obsoleteEntities.forEach((int id, Entity entity) {
      if (id == Game.player.id) {
        throw new Exception("Trying to remove the current player!");
      }
      Game.removeEntity(entity);
    });
    html.window.console.debug("Removed ${Game.obsoleteEntities.length} entities");
    Game.obsoleteEntities.clear();
  }

  /**
   * Fake a mouse move event in order to update the cursor.
   *
   * For instance, to get rid of the sword cursor in case the mouse is still hovering over a dying mob.
   * Also useful when the mouse is hovering a tile where an item is appearing.
   */
  static void updateCursor() {
    Game.updateHoverTargets();
    Game.updateCursorLogic();
  }

  /**
   * Change player plateau mode when necessary
   */
  static void updatePlateauMode() {
    Game.player.isOnPlateau = Game.map.isPlateau(Game.player.gridPosition);
  }

  /**
   * Links two entities in an attacker<-->target relationship.
   * This is just a utility method to wrap a set of instructions.
   *
   * @param {Entity} attacker The attacker entity
   * @param {Entity} target The target entity
   */
  static void createAttackLink(Character attacker, Character target) {
    if (attacker.hasTarget()) {
      attacker.removeTarget();
    }
    attacker.engage(target);

    if (Game.player != null && attacker.id != Game.player.id) {
      target.addAttacker(attacker);
    }
  }

  /**
    * Sends a "hello" message to the server, as a way of initiating the player connection handshake.
   */
  static void sendHello([bool isResurrection = false]) {
    Game.client.sendHello(Game.playerName, isResurrection);
  }

  /**
   * Converts the current mouse position on the screen to world grid coordinates.
   */
  static Position getMouseGridPosition() {
    int mx = Game.mouse.x;
    int my = Game.mouse.y;
    Camera c = Game.renderer.camera;
    int s = Game.renderer.scale;
    int ts = Game.renderer.tilesize;

    int offsetX = mx % (ts * s);
    int offsetY = my % (ts * s);

    return new Position(
      (((mx - offsetX) / (ts * s)) + c.gridPosition.x).round(),
      (((my - offsetY) / (ts * s)) + c.gridPosition.y).round()
    );
  }

  /**
   * Moves a character to a given location on the world grid.
   *
   * @param {Number} x The x coordinate of the target location.
   * @param {Number} y The y coordinate of the target location.
   */
   static void makeCharacterGoTo(Character character, Position position) {
    if (!Game.map.isOutOfBounds(position)) {
      character.go(position);
    }
  }

   static void makeCharacterTeleportTo(Character character, Position position) {
     if (Game.map.isOutOfBounds(position)) {
       html.window.console.debug("Teleport out of bounds: ${position}");
       return;
     }

     Game.unregisterEntityPosition(character);
     character.gridPosition = position;
     Game.registerEntityPosition(character);
     Game.assignBubbleTo(character);
   }

   // TODO: THIS CRAP IS ONLY CALLED FOR MOBILE BULLSHIT. SEE IF IT'S EVEN NEEDED.
   // @TODO: below
   // source might be a tile or an entity.
   // split into two functions and a helper
   static void checkOtherDirtyRects(Rect r1, dynamic source, Position position) {
     Game.forEachEntityAround(position, 2, (Entity entity) {
       if (source is Entity && source.id == entity.id) {
         return;
       }

       if (!entity.isDirty && r1.isIntersecting(Game.renderer.getEntityBoundingRect(entity))) {
         entity.dirty();
       }
     });

     if (source != null && !(source is AnimatedTile)) {
       Game.forEachAnimatedTile((Tile tile) {
         if (!tile.isDirty) {
           if (r1.isIntersecting(Game.renderer.getTileBoundingRect(tile))) {
             tile.isDirty = true;
           }
         }
       });
     }

     if (!Game.drawTarget && Game.selectedCellVisible) {
       Rect targetRect = Game.renderer.getTargetBoundingRect();
       if (r1.isIntersecting(targetRect)) {
         Game.drawTarget = true;
         Game.renderer.targetRect = targetRect;
       }
     }
   }

   static void assignBubbleTo(Character character) {
     Bubble bubble = Game.bubbleManager.getBubbleByID(character.id);
     if (bubble == null) {
       return;
     }

     int t = 16 * Game.renderer.scale; // tile size
     int x = ((character.x - Game.camera.x) * Game.renderer.scale);
     int w = (bubble.element.style.width.isEmpty ? 0 : int.parse(bubble.element.style.width)) + 24;
     int offset = ((w / 2) - (t / 2)).round();
     int offsetY;
     int y;

     if (character is Npc) {
       offsetY = 0;
     } else {
       if (Game.renderer.scale == 2) {
         if (Game.renderer.mobile) {
           offsetY = 0;
         } else {
           offsetY = 15;
         }
       } else {
         offsetY = 12;
       }
     }

     y = ((character.y - Game.camera.y) * Game.renderer.scale) - (t * 2) - offsetY;

     bubble.element.style.left = "${x - offset} px";
     bubble.element.style.top = "${y}px";
   }

   static void forEachEntity(void callback(Entity)) {
     var entities = new Map.from(Game.entities);
     entities.forEach((int id, Entity entity) {
       callback(entity);
     });
   }

   static void forEachCharacter(void callback(Character)) {
     var entities = new Map.from(Game.entities);
     entities.forEach((int id, Entity entity) {
       if (entity is Character) {
         callback(entity);
       }
     });
   }

   static void forEachMob(void callback(Mob)) {
     var entities = new Map.from(Game.entities);
     entities.forEach((int id, Entity entity) {
       if (entity is Mob) {
         callback(entity);
       }
     });
   }

   static void forEachAnimatedTile(void callback(AnimatedTile)) {
     var animatedTiles = new List.from(Game.animatedTiles);
     animatedTiles.forEach(callback);
   }

   static void forEachEntityAround(Position position, int radius, void callback(Entity)) {
     int maxX = position.x + radius;
     int maxY = position.y + radius;
     var entities = new Map<int, Entity>();

     // collect all entities around the entity, and then execute the callback
     // on each of them. we do this so changes while executing the callback
     // won't affect which entities we will process.
     for (var i = position.x - radius; i <= maxX; i += 1) {
       for (var j = position.y - radius; j <= maxY; j += 1) {
         if (!Game.map.isOutOfBounds(new Position(i, j))) {
           entities.addAll(Game.renderingGrid[j][i]);
         }
       }
     }

     entities.forEach((int id, Entity entity) {
       callback(entity);
     });
   }

   /**
    * Loops through all entities visible by the camera and sorted by depth :
    * Lower 'y' value means higher depth.
    * Note: This is used by the Renderer to know in which order to render entities.
    */
   static void forEachVisibleEntityByDepth(void callback(Entity)) {
     Game.camera.forEachVisiblePosition((Position position) {
       if (!Game.map.isOutOfBounds(position)) {
         Game.renderingGrid[position.y][position.x].forEach((int id, Entity entity) {
           callback(entity);
         });
       }
     }, Game.renderer.mobile ? 0 : 2);
   }

   static void forEachVisibleTileIndex(void callback(int index), [int extra = 0]) {
     Game.camera.forEachVisiblePosition((Position position) {
       if (!Game.map.isOutOfBounds(position)) {
         callback(Game.map.gridPositionToTileIndex(position) - 1);
       }
     }, extra);
   }

   static void forEachVisibleTile(void callback(int id, int index), [int extra = 0]) {
     if (!Game.map.isLoaded) {
       return;
     }

     Game.forEachVisibleTileIndex((int tileIndex) {
       if (Game.map.data[tileIndex] is List) {
         Game.map.data[tileIndex].forEach((int id) {
           callback(id - 1, tileIndex);
         });
         return;
       }
       
       if (Game.map.data[tileIndex] is int) {
         callback(Game.map.data[tileIndex] - 1, tileIndex);
         return;
       }

       throw new Exception("Game.forEachVisibleTile: unsupported type '${Game.map.data[tileIndex]}'");
     }, extra);
   }

   /**
     * Returns the entity located at the given position on the world grid.
     * @returns {Entity} the entity located at (x, y) or null if there is none.
     */
   static Entity getEntityAt(Position position) {
     if (Game.map.isOutOfBounds(position)) {
       return null;
     }

     if (Game.entityGrid[position.y][position.x].length > 0) {
       return Game.entityGrid[position.y][position.x].values.first;
     }

     return Game.getItemAt(position);
   }

   static Player getPlayerAt(Position position) {
     Entity entity = Game.getEntityAt(position);
     return (entity != null && entity is Player) ? entity : null;
   }

   static Mob getMobAt(Position position) {
     Entity entity = Game.getEntityAt(position);
     return (entity != null && entity is Mob) ? entity : null;
   }

   static Item getItemAt(Position position) {
     if (Game.map.isOutOfBounds(position)) {
       return null;
     }

     if (Game.itemGrid[position.y][position.x].length == 0) {
       return null;
     }

     // If there are potions/burgers stacked with equipment items on the same tile>
     for (final item in Game.itemGrid[position.y][position.x].values) {
       if (Types.isExpendableItem(item.kind)) {
         return item;
       }
     }

     return Game.itemGrid[position.y][position.x].values.first;
   }

   static Npc getNpcAt(Position position) {
     Entity entity = Game.getEntityAt(position);
     return (entity != null && entity is Npc) ? entity : null;
   }

   static Chest getChestAt(Position position) {
     Entity entity = Game.getEntityAt(position);
     return (entity != null && entity is Chest) ? entity : null;
   }

   static bool isEntityAt(Position position) => Game.getEntityAt(position) != null;
   static bool isPlayerAt(Position position) => Game.getPlayerAt(position) != null;
   static bool isMobAt(Position position) => Game.getMobAt(position) != null;
   static bool isItemAt(Position position) => Game.getItemAt(position) != null;
   static bool isNpcAt(Position position) => Game.getNpcAt(position) != null;
   static bool isChestAt(Position position) => Game.getChestAt(position) != null;

   static bool isZoningTile(Position position) {
     int x = position.x - Game.camera.gridPosition.x;
     int y = position.y - Game.camera.gridPosition.y;

     return x == 0
       || y == 0
       || x == Game.camera.gridW - 1
       || y == Game.camera.gridH - 1;
   }

   static Orientation getZoningOrientation(Position position) {
     int x = position.x - Game.camera.gridPosition.x;
     int y = position.y - Game.camera.gridPosition.y;

     if (x == 0) {
       return Orientation.LEFT;
     } else if (y == 0) {
       return Orientation.UP;
     } else if (x == Game.camera.gridW - 1) {
       return Orientation.RIGHT;
     } else if (y == Game.camera.gridH - 1) {
       return Orientation.DOWN;
     }

     // TODO: can this be ever null? what does it mean for the callsites?
     // investigate.
     return null;
   }

   static void startZoningFrom(Position position) {
     Game.zoningOrientation = Game.getZoningOrientation(position);

     // TODO: remove this mobile crap
     /*
     if (this.renderer.mobile || this.renderer.tablet) {
       var z = this.zoningOrientation,
         c = this.camera,
         ts = this.renderer.tilesize,
         x = c.x,
         y = c.y,
         xoffset = (c.gridW - 2) * ts,
         yoffset = (c.gridH - 2) * ts;

       if (z === Types.Orientations.LEFT || z === Types.Orientations.RIGHT) {
         x = (z === Types.Orientations.LEFT) ? c.x - xoffset : c.x + xoffset;
       } else if (z === Types.Orientations.UP || z === Types.Orientations.DOWN) {
         y = (z === Types.Orientations.UP) ? c.y - yoffset : c.y + yoffset;
       }
       c.setPosition(x, y);

       this.renderer.clearScreen(this.renderer.context);
       this.endZoning();

       // Force immediate drawing of all visible entities in the new zone
       this.forEachVisibleEntityByDepth((entity) {
         entity.dirty();
       });
     } else {
       this.currentZoning = new Transition();
     }
     */
     Game.currentZoning = new Transition();
     Game.bubbleManager.clean();
     Game.client.sendZone();
   }

   static bool isZoning() {
     return Game.currentZoning != null;
   }

   static void endZoning() {
     Game.currentZoning = null;
     Game.resetZone();

     if (Game.zoningQueue.length > 0) {
       Game.zoningQueue.removeAt(0);
     }

     if (Game.zoningQueue.length > 0) {
       Game.startZoningFrom(Game.zoningQueue[0]);
     }
   }

   static void enqueueZoningFrom(Position position) {
     Game.zoningQueue.add(position);
     if (Game.zoningQueue.length == 1) {
       Game.startZoningFrom(position);
     }
   }

   /**
    * Moves the player one space, if possible
    */
   static void keys(Position pos, Orientation orientation) {
     bool oldIsHoveringColliding = Game.isHoveringCollidingTile;
     Game.isHoveringCollidingTile = false;

     Game.player.orientation = orientation;
     Game.player.idle();
     Game.processInput(pos, true);

     Game.isHoveringCollidingTile = oldIsHoveringColliding;
   }
   
   static void click() {
     Game.selectedCellVisible = true;

     Position pos = Game.getMouseGridPosition();
     if (pos == Game.previousClickPosition) {
       return;
     }
     
     Game.previousClickPosition = pos;
     Game.processInput(pos);
   }

   static void checkUndergroundAchievement() {
     Audio music = Game.audioManager.getSurroundingMusic(Game.player);
     if (music != null && music.name == 'cave') {
       Game.tryUnlockingAchievement("UNDERGROUND");
     }
   }

   static void resetZone() {
     Game.bubbleManager.clean();
     Game.initAnimatedTiles();
     Game.renderer.renderStaticCanvases();
   }

   static void updateHoverTargets() {
     Position mousePosition = Game.getMouseGridPosition();

     if (Game.player == null
        || Game.renderer.mobile
        || Game.renderer.tablet) {
       return;
     }

     Game.isHoveringCollidingTile = Game.map.isColliding(mousePosition);
     Game.isHoveringPlateauTile = Game.player.isOnPlateau != Game.map.isPlateau(mousePosition);

     // The order of choose which entity the player is hovering is defined here.
     // we are resetting everything first to make sure we won't have any data
     // left over from a previous mouse location.
     Game.hoveringMob = null;
     Game.hoveringItem = null;
     Game.hoveringNpc = null;
     Game.hoveringChest = null;
     Entity entity;
     while (true) {
       entity = Game.hoveringPlayer = Game.getPlayerAt(mousePosition);
       if (entity != null) break;

       entity = Game.hoveringMob = Game.getMobAt(mousePosition);
       if (entity != null) break;

       entity = Game.hoveringNpc = Game.getNpcAt(mousePosition);
       if (entity != null) break;

       entity = Game.hoveringChest = Game.getChestAt(mousePosition);
       if (entity != null) break;

       entity = Game.hoveringItem = Game.getItemAt(mousePosition);
       if (entity != null) break;

       break;
     }

     if (entity != null) {
       if (!entity.isHighlighted && Game.renderer.supportsSilhouettes) {
         if (Game.lastHoveredEntity != null) {
           Game.lastHoveredEntity.setHighlight(false);
         }
         Game.lastHoveredEntity = entity;
         entity.setHighlight(true);
       }
     } else if (Game.lastHoveredEntity != null) {
       Game.lastHoveredEntity.setHighlight(false);
       Game.lastHoveredEntity = null;
     }
   }

   /**
    * Processes game logic when the user triggers a click/touch event during the gam>
    */
   // TODO: I'm sure this can be simplified / commented and prettified. Do it.
   static void processInput(Position position, [bool isKeyboard = false]) {
     if (Game.started
         && Game.player != null
         && !Game.isZoning()
         && !Game.isZoningTile(new Position(Game.player.nextGridX, Game.player.nextGridY))
         && !Game.player.isDead
         && !Game.isHoveringCollidingTile
         && !Game.isHoveringPlateauTile) {
       Entity entity = Game.getEntityAt(position);

       if (!isKeyboard && entity != null && entity.interactable) {
         if (entity is Mob || entity is Player) {
           Game.player.target = entity;
         } else if (entity is Item) {
           Game.makePlayerGoToItem(entity);
         } else if (entity is Npc) {
           if (!Game.player.isAdjacentNonDiagonal(entity)) {
             Game.makePlayerTalkTo(entity);
           } else {
             Game.makeNpcTalk(entity);
           }
         } else if (entity is Chest) {
           Game.makePlayerOpenChest(entity);
         }
       } else {
         Game.makePlayerGoTo(position);
       }
     }
   }

   static void updatePlayerCheckpoint() {
     Checkpoint checkpoint = Game.map.getCurrentCheckpoint(Game.player);
     if (checkpoint == null) {
       return;
     }

     Game.client.sendCheck(checkpoint.id);
   }

   // TODO: convert to events
   static void playerChangedEquipment() {
     Game.app.initEquipmentIcons();
   }

   static void playerDeath() {
     Game.app.playerDeath();
   }

   static void playerInvincible(bool state) {
     Game.app.playerInvincible(state);
   }

   /**
     * Finds a path to a grid position for the specified character.
     * The path will pass through any entity present in the ignore list.
     */
    static List<List<int>> findPath(Character character, Position position, List<Entity> ignoreList) {
       if (Game.map.isColliding(position)) {
         return [];
       }

       List<List<int>> path = [];
       if (Game.pathfinder != null && character != null) {
         if (ignoreList != null) {
           ignoreList.forEach((Entity entity) {
             Game.pathfinder.ignoreEntity(entity);
           });
         }

         path = Game.pathfinder.findPath(Game.pathingGrid, character, position, false);

         if (ignoreList != null) {
           Game.pathfinder.clearIgnoreList();
         }
       } else {
         html.window.console.error("Error while finding the path to $position for ${character.id}");
       }

       return path;
    }
    
    static void say(String message) {
      if (!message.startsWith('/')) {
        // no command given - this is a message to the default chat channel
        Game.client.sendChat(message);
        return;
      }
      
      // command given
      var firstSpaceIndex = message.indexOf(' ');
      var command = message.substring(1, firstSpaceIndex > -1 ? firstSpaceIndex : message.length);
      var rest = message.substring(firstSpaceIndex > -1 ? firstSpaceIndex + 1 : message.length);
      var args = message.substring(1).split(' ');

      if (command == "global") {
        Game.client.chat.channel = "global";
        Game.client.sendChat(rest);
      } else if (command == "say" || command == "s") {
        Game.client.chat.channel = "say";
        Game.client.sendChat(rest);
      } else if (command == "yell" || command == "y") {
        Game.client.chat.channel = "yell";
        Game.client.sendChat(rest);
      } else if (command == "party" || command == "p") {
        if (Game.player.party == null) {
          Game.client.error("You are not in a party.");
          return;
        }
        Game.client.chat.channel = "party";
        Game.client.sendChat(rest);
      } else if (command == "guild" || command == "g") {
        if (Game.player.guild == null) {
          Game.client.error("You are not in a guild.");
          return;
        }
        Game.client.chat.channel = "guild";
        Game.client.sendChat(rest);
      } else if (command == "invite") {
        Player player = Game.getPlayerByName(args[1]);
        if (player == null) {
          Game.client.error("Unknown player '${args[1]}'.");
          return;
        }

        if (player == Game.player) {
          Game.client.error("You cannot invite yourself to a party.");
          return;
        }

        if (Game.player.party != null) {
          if (!Game.player.party.isLeader(Game.player)) {
            Game.client.error("You must be the party leader to invite players.");
            return;
          }

          if (Game.player.party.isFull()) {
            Game.client.error("Your party is full. You cannot invite any one to it.");
            return;
          }
        }

        Game.client.notice("Invited ${player.name} to your party.");
        Game.client.sendPartyInvite(player.id);
      } else if (command == "kick") {
        Player player = Game.getPlayerByName(args[1]);
        if (player == null) {
          Game.client.error("Unknown player '${args[1]}'.");
          return;
        }

        if (Game.player.party == null) {
          Game.client.error("You are not in a party.");
          return;
        }

        if (!Game.player.party.isLeader(Game.player)) {
          Game.client.error("You must be the party leader to kick players.");
          return;
        }

        if (player == Game.player) {
          Game.client.error("You cannot kick yourself from a party.");
          return;
        }

        if (!Game.player.party.isMember(player)) {
          Game.client.error("${player.name} is not a member of your party.");
          return;
        }

        Game.client.sendPartyKick(player.id);
      } else if (command == "accept") {
        Player player = Game.getPlayerByName(args[1]);
        if (player == null) {
          Game.client.error("Unknown player '${args[1]}'.");
          return;
        }

        Game.client.sendPartyAccept(player.id);
      } else if (command == "leave") {
        Game.client.sendPartyLeave();
      } else if (command == "leader") {
        Player player = Game.getPlayerByName(args[1]);
        if (player == null) {
          Game.client.error("Unknown player '${args[1]}'.");
          return;
        }

        if (!Game.player.party.isLeader(Game.player)) {
          Game.client.error("Only the party leader can promote a new leader.");
          return;
        }

        Game.client.sendPartyLeaderChange(player.id);
      } else if (command == "gcreate") {
        String name = rest;
        if (name.isEmpty) {
          Game.client.error("Syntax: /gcreate <Guild Name>");
          return;
        }

        Game.client.sendGuildCreate(name);
      } else if (command == "ginvite") {
        String name = args[1];
        if (name.isEmpty) {
          Game.client.error("Syntax: /ginvite <Player Name>");
          return;
        }

        Game.client.sendGuildInvite(name);
      } else if (command == "gkick") {
        String name = args[1];
        if (name.isEmpty) {
          Game.client.error("Syntax: /gkick <Player Name>");
          return;
        }

        Game.client.sendGuildKick(name);
      } else if (command == "gaccept") {
        String name = args[1];
        if (name.isEmpty) {
          Game.client.error("Syntax: /gaccept <Player Name>");
          return;
        }

        Game.client.sendGuildAccept(name);
      } else if (command == "gquit") {
        Game.client.sendGuildQuit();
      } else if (command == "gleader") {
        String name = args[1];
        if (name.isEmpty) {
          Game.client.error("Syntax: /gleader <Player Name>");
          return;
        }

        Game.client.sendGuildLeaderChange(name);
      } else if (command == "gmembers") {
        Game.client.sendGuildMembers();
      } else {
        Game.client.error("Unknown command '${command}' given.");
      }
    }

    static void createBubble(Entity entity, String message) {
      Game.bubbleManager.create(entity, message);
    }

    static void destroyBubble(int id) {
      Game.bubbleManager.destroy(id);
    }

    static void makePlayerGoToItem(Item item) {
      Game.player.isLootMoving = true;
      Game.makePlayerGoTo(item.gridPosition);
      Game.client.sendMove(new Position(item.x, item.y));
    }

    static void makePlayerTalkTo(Npc npc) {
      Game.player.setTarget(npc);
      Game.player.follow(npc);
    }

    static void makePlayerOpenChest(Chest chest) {
      Game.player.setTarget(chest);
      Game.player.follow(chest);
    }

    static void makePlayerAttack(Mob mob) {
      Game.createAttackLink(Game.player, mob);
      Game.client.sendAttack(mob);
    }

    static void makePlayerAttackTarget() {
      if (Game.player.target != null) {
        Game.makePlayerAttack(Game.player.target);
      }
    }

    static void makePlayerAttackTo(Position position) {
      Entity entity = Game.getEntityAt(position);
      if (Game.player.isHostile(entity)) {
        Game.makePlayerAttack(entity);
      }
    }

    static void makePlayerGoTo(Position position) {
      Game.makeCharacterGoTo(Game.player, position);
    }

    static void makeNpcTalk(Npc npc) {
      String msg = npc.talk();
      Game.previousClickPosition = null;
      if (msg.length > 0) {
        Game.createBubble(npc, msg);
        Game.assignBubbleTo(npc);
        Game.audioManager.playSound("npc");
      } else {
        Game.destroyBubble(npc.id);
        Game.audioManager.playSound("npc-end");
      }
      Game.tryUnlockingAchievement("SMALL_TALK");

      if (npc.kind == Entities.RICK) {
        Game.tryUnlockingAchievement("RICKROLLD");
      }

    }
    
    static void makePlayerTargetNearestEnemy() {
      var enemies = Game.player.getNearestEnemies();
      if (enemies.length > 0) {
        Game.player.setTarget(enemies[0]);
      }
    }

    static void makePlayerAttackNext() {
      switch (Game.player.orientation) {
        case Orientation.DOWN:
          Game.makePlayerAttackTo(Game.player.gridPosition.incY());
          break;
          
        case Orientation.UP:
          Game.makePlayerAttackTo(Game.player.gridPosition.decY());
          break;
          
        case Orientation.LEFT:
          Game.makePlayerAttackTo(Game.player.gridPosition.decX());
          break;
          
        case Orientation.RIGHT:
          Game.makePlayerAttackTo(Game.player.gridPosition.incX());
          break;
      }
    }    

    static void setSpriteScale(int scale) {
      if (scale < 0 || scale > 2) {
        throw new Exception("Unsupported scale $scale");
      }

      if (Game.renderer.upscaledRendering) {
        Game.sprites = Game.spriteSets[0];
      } else {
        Game.sprites = Game.spriteSets[scale - 1];

        Game.entities.forEach((int id, Entity entity) {
          entity.setSprite(Game.sprites[entity.getSpriteName()]);
        });
        Game.initHurtSprites();
        Game.initShadows();
        Game.initCursors();
      }
    }

    static void disconnected(String message) {
      Game.app.disconnected(message);
    }

    static void updateCharacter(Character character) {
      int time = Game.currentTime;

      // If mob has finished moving to a different tile in order to avoid stacking, a>
      if (character.previousTarget != null
          && !character.isMoving()
          && character is Mob) {
        var t = character.previousTarget;

        if (Game.getEntityByID(t.id) != null) { // does it still exist?
          character.previousTarget = null;
          Game.createAttackLink(character, t);
          return;
        }
      }

      if (character.isAttacking() && character.previousTarget == null) {

        // TODO: this is stupid. we don't want this behavior, nor the client
        //       suppose to take care of this.

        // Don't let multiple mobs stack on the same tile when attacking a player.
        bool isMoving = false; // Game.tryMovingToADifferentTile(character);
        if (character.canAttack(time)) {
          if (!isMoving) { // don't hit target if moving to a different tile.
            if (character.hasTarget()
                && character.getOrientationTo(character.target) != character.orientation) {
              character.lookAtTarget();
            }

            character.hit();

            if (Game.player != null && character.id == Game.player.id) {
              Game.client.sendHit(character.target);
            }

            if (character is Player && Game.camera.isVisible(character)) {
              Random rng = new Random();
              Game.audioManager.playSound("hit${(rng.nextInt(1) + 1)}");
            }

            // TODO: this shouldn't be here, it should be on the server
            if (character.hasTarget()
                && Game.player != null
                && character.target.id == Game.player.id
                && !Game.player.isInvincible) {
              Game.client.sendHurt(character);
            }
          }
        } else if (character.hasTarget()
                   && character.isDiagonallyAdjacent(character.target)
                   && character.target is Player
                   && !character.target.isMoving()) {
          character.follow(character.target);
        }
      }
    }

    static void connect(Function started_callback) {
      bool connecting = false; // always in dispatcher mode in the build version

      Game.client = new GameClient(Game.host, Game.port);
      Game.client.chat.input = Game.chatInput;

      Game.client.connect(Game.app.config.dispatcher); // false if the client connects directly to a game server
      connecting = true;

      Game.client.on("Dispatched", (host, port) {
        html.window.console.debug("Dispatched to game server $host:$port");

        Game.client.host = host;
        Game.client.port = port;
        Game.player.isDying = false;
        Game.client.connect(); // connect to actual game server
      });

      Game.client.on("Connected", () {
        html.window.console.info("Starting client/server handshake");

        Game.playerName = Game.username;
        Game.started = true;

        Game.sendHello();
      });

      Game.client.on("EntityList", (List<int> list) {
        List<int> entityIds = Game.entities.keys.toList();
        List<int> knownIds = list.where((int id) => entityIds.contains(id)).toList();
        List<int> newIds = list.where((int id) => !knownIds.contains(id)).toList();

        Game.obsoleteEntities.clear();
        var entities = new Map.from(Game.entities);
        entities.forEach((int id, Entity entity) {
          if (knownIds.contains(id) || id == Game.player.id) {
            return;
          }

          Game.obsoleteEntities[id] = entity;
        });

        // Destroy entities outside of the player's zone group
        Game.removeObsoleteEntities();

        // Ask the server for spawn information about unknown entities
        if (newIds.length > 0) {
          Game.client.sendWho(newIds);
        }
      });

      Game.client.on("Welcome", (data) {
        // Player
        if (Game.player != null) {
          Game.player.idle();
          Game.player.isRemoved = false;
        } else {
          // TODO: fix to a proper id, ideally from the server
          Game.player = new Hero(13371337, "Newbie");
        }

        // make events from player to bubble to game
        Game.player.bubbleTo(Game.events);

        Game.app.initBars();
        html.window.console.debug("initiated bars");

        Game.player.isDead = false;
        Game.player.isDying = false;

        Game.player.loadFromObject(data);

        Game.addPlayer(Game.player);

        html.window.console.info("Received player ID from server ${Game.player.id}");

        Game.updateBars();
        Game.resetCamera();
        Game.updatePlateauMode();
        Game.audioManager.updateMusic();

        Game.addEntity(Game.player);
        Game.player.dirtyRect = Game.renderer.getEntityBoundingRect(Game.player);

        Game.initPlayer();
        Game.player.idle();

        // TODO: implement differently
        /*
        if (!Game.storage.hasAlreadyPlayed()) {
          Game.storage.initPlayer(Game.player.name);
          Game.storage.savePlayer(Game.renderer.getPlayerImage(), Game.player);
          Game.showNotification("Welcome to BrowserQuest!");
        } else {
          Game.showNotification("Welcome back to BrowserQuest!");
        }
        */

        if (Game.hasNeverStarted) {
          Game.start();
          started_callback();
        }

        Game.tryUnlockingAchievement("STILL_ALIVE");
      });
    }

    static void initPlayer() {
      // TODO: implement differently
//      Game.player.setStorage(Game.storage);
//      Game.player.loadFromStorage(() {
//        Game.updateBars();
//      });

      // TODO: meh. refactor setSprite mechanics
      Game.player.setSprite(Game.sprites["clotharmor"]);
      html.window.console.debug("Finished initPlayer");
    }

    static void resetCamera() {
      Game.camera.focusEntity(Game.player);
      Game.resetZone();
    }
    
    static void resize() {
      Camera camera = Game.camera;

      Game.renderer.rescale();
      Game.camera = Game.renderer.camera;
      Game.camera.gridPosition = camera.gridPosition;

      Game.renderer.renderStaticCanvases();
    }
    
    /**
     * Toggles the visibility of the pathing grid for debugging purposes.
     */
    static void togglePathingGrid() {
      Game.debugPathing = !Game.debugPathing;
    }

    /**
     * Toggles the visibility of the FPS counter and other debugging info.
     */
    static void toggleDebugInfo() {
      Game.renderer.isDebugInfoVisible = Game.renderer == null || !Game.renderer.isDebugInfoVisible; 
    }
}
