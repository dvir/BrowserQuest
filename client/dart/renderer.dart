library renderer;

import "dart:html" as html;

import "animatedtile.dart";
import "animation.dart";
import "animationtimer.dart";
import "base.dart";
import "camera.dart";
import "character.dart";
import "chatmessage.dart";
import "entity.dart";
import "game.dart";
import "info.dart";
import "item.dart";
import "party.dart";
import "player.dart";
import "position.dart";
import "rect.dart";
import "sprite.dart";
import "tile.dart";
import "lib/gametypes.dart";

int getX(id, w) {
  if (id == 0) {
    return 0;
  }
  return (id % w == 0) ? w - 1 : (id % w) - 1;
}

class Renderer extends Base {

  html.CanvasElement canvas;
  html.CanvasElement backcanvas;
  html.CanvasElement forecanvas;
  html.CanvasRenderingContext2D context;
  html.CanvasRenderingContext2D background;
  html.CanvasRenderingContext2D foreground;
  int tilesize = 16;
  DateTime lastTime;
  int frameCount = 0;
  int FPS = 50;
  int maxFPS; 
  int realFPS = 0;
  bool isDebugInfoVisible = false;
  int animatedTileCount = 0;
  int highTileCount = 0;
  html.ImageElement _tileset;
  int scale;
  Camera camera;
  Position lastTargetPos;
  Rect targetRect;
  AnimationTimer fixFlickeringTimer = new AnimationTimer(new Duration(milliseconds: 100));

  // TODO: update to fetch real values
  bool upscaledRendering = false;
  bool supportsSilhouettes = false;
  bool tablet = false;

  Renderer(
    html.CanvasElement this.canvas, 
    html.CanvasElement this.backcanvas, 
    html.CanvasElement this.forecanvas
  ) {
    this.context = this.canvas.getContext("2d");
    this.background =  this.backcanvas.getContext("2d");
    this.foreground =  this.forecanvas.getContext("2d");

    this.fixFlickeringTimer.on("Tick", () {
      this.background.fillRect(0, 0, 0, 0);
      this.context.fillRect(0, 0, 0, 0);
      this.foreground.fillRect(0, 0, 0, 0);
    });

    this.lastTime = new DateTime.now();
    this.maxFPS = this.FPS;

    this.initFPS();
    this.rescale();
  }

  int get width => this.canvas.width;
  int get height => this.canvas.height;
  
  html.ImageElement get tileset => this._tileset;
  void set tileset(html.ImageElement tileset) {
    this._tileset = tileset;
  }
  
  bool get mobile => html.window.innerWidth <= 1000;

  int getScaleFactor() {
    if (html.window.innerWidth <= 1000) {
      return 2;
    }

    if (html.window.innerWidth <= 1500 || html.window.innerHeight <= 870) {
      return 2;
    }

    return 3;
  }

  void rescale() {
    this.scale = this.getScaleFactor();

    this.createCamera();

    this.context.imageSmoothingEnabled = false;
    this.background.imageSmoothingEnabled = false;
    this.foreground.imageSmoothingEnabled = false;

    this.initFont();
    this.initFPS();

    if (!this.upscaledRendering && Game.map != null) {
      this.tileset = Game.map.tilesets[this.scale - 1];
    }
    if (Game.renderer != null) {
      Game.setSpriteScale(this.scale);
    }
  }

  void createCamera() {
    this.camera = new Camera(this);
    this.camera.rescale();

    this.canvas.width = this.camera.gridW * this.tilesize * this.scale;
    this.canvas.height = this.camera.gridH * this.tilesize * this.scale;

    this.backcanvas.width = this.canvas.width;
    this.backcanvas.height = this.canvas.height;

    this.forecanvas.width = this.canvas.width;
    this.forecanvas.height = this.canvas.height;
  }

  void initFPS() {
    this.FPS = this.mobile ? 50 : 50;
  }

  void initFont() {
    switch (this.scale) {
      case 1:
        this.setFontSize(10);
        return;
      case 2:
        this.setFontSize(13);
        return;
      case 3:
        this.setFontSize(20);
        return;
    }

    throw "Unsupported scale ${this.scale}";
  }

  void setFontSize(int size) {
    String font = "${size}px GraphicPixel";
    this.context.font = font;
    this.background.font = font;
  }
  
  void drawText(
    String text, 
    Position pos,
    bool centered, 
    [
      String color = "white", 
      String strokeColor = "#373737", 
      String align
    ]
  ) {
    int x = pos.x;
    int y = pos.y;
    if (x < 0) x += this.canvas.width;
    if (y < 0) y += this.canvas.height;

    int strokeSize;
    switch (this.scale) {
      case 1:
        strokeSize = 3;
        break;
      case 2:
        strokeSize = 3;
        break;
      case 3:
        strokeSize = 5;
        break;
    }

    this.context.save();
    if (centered) {
      this.context.textAlign = "center";
    }
    if (align != null) {
      this.context.textAlign = align;
    }
    this.context.strokeStyle = strokeColor;
    this.context.lineWidth = strokeSize;
    this.context.strokeText(text, x, y);
    this.context.fillStyle = color;
    this.context.fillText(text, x, y);
    this.context.restore();
  }

  void drawCellRect(Position pos, String color) {
    this.context.save();
    this.context.lineWidth = 2 * this.scale;
    this.context.strokeStyle = color;
    this.context.translate(pos.x + 2, pos.y + 2);
    this.context.strokeRect(0, 0, (this.tilesize * this.scale) - 4, (this.tilesize * this.scale) - 4);
    this.context.restore();
  }

  void drawCellHighlight(Position pos, String color) {
    this.drawCellRect(
      new Position(
        pos.x * this.tilesize * this.scale,
        pos.y * this.tilesize * this.scale
      ),
      color
    );
  }

  void drawTargetCell() {
    Position mouse = Game.getMouseGridPosition();
    if (Game.targetCellVisible && (mouse != Game.selected)) {
      this.drawCellHighlight(mouse, Game.targetColor);
    }
  }

  void drawAttackTargetCell() {
    Position mouse = Game.getMouseGridPosition();
    Entity entity = Game.getEntityAt(mouse);

    if (entity != null) {
      this.drawCellRect(
        new Position(
          entity.x * this.scale,
          entity.y * this.scale
        ),
        "rgba(255, 0, 0, 0.5)"
      );
    }
  }

  void drawOccupiedCells() {
    List<List<Map<int, Entity>>> positions = Game.entityGrid;

    for (int i = 0; i < positions.length; i += 1) {
      for (int j = 0; j < positions[i].length; j += 1) {
        if (positions[i][j].isNotEmpty) {
          this.drawCellHighlight(new Position(i, j), "rgba(50, 50, 255, 0.5)");
        }
      }
    }
  }

  void drawPathingCells() {
    List<List<int>> grid = Game.pathingGrid;

    if (Game.debugPathing) {
      for (int y = 0; y < grid.length; y++) {
        for (int x = 0; x < grid[y].length; x++) {
          if (grid[y][x] == 1 && Game.camera.isVisiblePosition(x, y)) {
            this.drawCellHighlight(new Position(x, y), "rgba(50, 50, 255, 0.5)");
          }
        }
      }
    }
  }

  void drawSelectedCell() {
    Sprite sprite = Game.cursors["target"];
    Animation anim = Game.targetAnimation;
    int os = this.upscaledRendering ? 1 : this.scale;
    int ds = this.upscaledRendering ? this.scale : 1;

    if (!Game.selectedCellVisible) {
      return;
    }

    if (this.mobile || this.tablet) {
      if (Game.drawTarget) {
        this.drawCellHighlight(Game.selected, "rgb(51, 255, 0)");
        this.lastTargetPos = Game.selected;
        Game.drawTarget = false;
      }

      return;
    }

    if (sprite == null || anim == null) {
      return;
    }

    Frame frame = anim.currentFrame;
    int x = frame.x * os;
    int y = frame.y * os;
    int w = sprite.width * os;
    int h = sprite.height * os;
    int ts = 16;
    int dx = Game.selected.x * ts * this.scale;
    int dy = Game.selected.y * ts * this.scale;
    int dw = w * ds;
    int dh = h * ds;

    this.context.save();
    this.context.translate(dx, dy);
    this.context.drawImageScaledFromSource(sprite.image, x, y, w, h, 0, 0, dw, dh);
    this.context.restore();
  }

  void clearScaledRect(ctx, x, y, w, h) {
    ctx.clearRect(x * this.scale, y * this.scale, w * this.scale, h * this.scale);
  }

  void drawCursor() {
    var mx = Game.mouse.x,
      my = Game.mouse.y,
      s = this.scale,
      os = this.upscaledRendering ? 1 : this.scale;

    this.context.save();
    if (Game.currentCursor != null && Game.currentCursor.isLoaded) {
      this.context.drawImageScaledFromSource(Game.currentCursor.image, 0, 0, 14 * os, 14 * os, mx, my, 14 * s, 14 * s);
    }
    this.context.restore();
  }

  void drawScaledImage(
    html.CanvasRenderingContext2D ctx, 
    html.ImageElement image, 
    int x, 
    int y, 
    int w, 
    int h, 
    int dx, 
    int dy
  ) {
    var s = this.upscaledRendering ? 1 : this.scale;

    ctx.drawImageScaledFromSource(
      image,
      x * s,
      y * s,
      w * s,
      h * s,
      dx * this.scale,
      dy * this.scale,
      w * this.scale,
      h * this.scale
    );
  }

  void drawTile(ctx, tileid, tileset, setW, gridW, cellid) {
    int s = this.upscaledRendering ? 1 : this.scale;
    if (tileid != -1) { // -1 when tile is empty in Tiled. Don't attempt to draw it.
      this.drawScaledImage(
        ctx,
        tileset,
        getX(tileid + 1, (setW / s)) * this.tilesize,
        (tileid / (setW / s)).floor() * this.tilesize,
        this.tilesize,
        this.tilesize,
        getX(cellid + 1, gridW) * this.tilesize,
        (cellid / gridW).floor() * this.tilesize
      );
    }
  }

  void clearTile(ctx, gridW, cellid) {
    int x = getX(cellid + 1, gridW) * this.tilesize * this.scale;
    int y = (cellid / gridW).floor() * this.tilesize * this.scale;
    int w = this.tilesize * this.scale;
    int h = w;

    ctx.clearRect(x, y, h, w);
  }

  void drawEntity(Entity entity) {
    String kindString = entity.getSpriteName();

    Sprite sprite = Game.sprites[kindString];
    Sprite shadow = Game.shadows["small"];
    Animation anim = entity.currentAnimation;
    int os = this.upscaledRendering ? 1 : this.scale;
    int ds = this.upscaledRendering ? this.scale : 1;

    if (anim != null) {
      return;
    }

    Frame frame = anim.currentFrame;
    int x = frame.x * os;
    int y = frame.y * os;
    int w = sprite.width * os;
    int h = sprite.height * os;
    int ox = sprite.offsetX * this.scale;
    int oy = sprite.offsetY * this.scale;
    int dx = entity.x * this.scale;
    int dy = entity.y * this.scale;
    int dw = w * ds;
    int dh = h * ds;

    if (entity.isRemoved) {
      // @TODO: remove from grid?
      return;
    }

    if (entity.isFading) {
      this.context.save();
      this.context.globalAlpha = entity.fadingAlpha;
    }

    if (!this.mobile && !this.tablet) {
      this.drawEntityName(entity);
    }

    this.context.save();
    if (entity.flipSpriteX) {
      this.context.translate(dx + this.tilesize * this.scale, dy);
      this.context.scale(-1, 1);
    } else if (entity.flipSpriteY) {
      this.context.translate(dx, dy + dh);
      this.context.scale(1, -1);
    } else {
      this.context.translate(dx, dy);
    }

    if (entity.isVisible) {
      if (entity.hasShadow()) {
        this.context.drawImageScaledFromSource(shadow.image, 0, 0, shadow.width * os, shadow.height * os,
          0,
          entity.shadowOffsetY * ds,
          shadow.width * os * ds, shadow.height * os * ds);
      }

      this.context.drawImageScaledFromSource(sprite.image, x, y, w, h, ox, oy, dw, dh);

      if (entity is Item && entity.kind != Entities.CAKE) {
        Sprite sparks = Game.sprites["sparks"];
        Animation sparksAnimation = Game.sparksAnimation;
        Frame frame = sparksAnimation.currentFrame;
        int sx = sparks.width * frame.index * os;
        int sy = sparks.height * sparksAnimation.row * os;
        int sw = sparks.width * os;
        int sh = sparks.width * os;

        this.context.drawImageScaledFromSource(sparks.image, sx, sy, sw, sh,
          sparks.offsetX * this.scale,
          sparks.offsetY * this.scale,
          sw * ds, sh * ds);
      }
    }

    if (entity is Character && !entity.isDead && entity.hasWeapon()) {
      Sprite weapon = Game.sprites[Types.getKindAsString(entity.weapon)];
      var weaponAnimData = weapon.animationData[anim.name];
      var index = frame.index < weaponAnimData.length ? frame.index : frame.index % weaponAnimData.length;
      int wx = weapon.width * index * os;
      int wy = weapon.height * anim.row * os;
      int ww = weapon.width * os;
      int wh = weapon.height * os;

      this.context.drawImageScaledFromSource(weapon.image, wx, wy, ww, wh,
        weapon.offsetX * this.scale,
        weapon.offsetY * this.scale,
        ww * ds, wh * ds);
    }

    this.context.restore();

    if (entity.isFading) {
      this.context.restore();
    }
  }

  void drawEntities([bool dirtyOnly = false]) {
    Game.forEachVisibleEntityByDepth((Entity entity) {
      if (!entity.isLoaded) {
        return;
      }

      if (dirtyOnly) {
        if (entity.isDirty) {
          this.drawEntity(entity);

          entity.isDirty = false;
          entity.oldDirtyRect = entity.dirtyRect;
          entity.dirtyRect = null;
        }
      } else {
        this.drawEntity(entity);
      }
    });
  }

  void drawDirtyEntities() {
    this.drawEntities(true);
  }

  void clearDirtyRect(r) {
    this.context.clearRect(r.x, r.y, r.w, r.h);
  }

  void clearDirtyRects() {
    Game.forEachVisibleEntityByDepth((Entity entity) {
      if (entity.isDirty && entity.oldDirtyRect != null) {
        this.clearDirtyRect(entity.oldDirtyRect);
      }
    });

    Game.forEachAnimatedTile((Tile tile) {
      if (tile.isDirty) {
        this.clearDirtyRect(tile.dirtyRect);
      }
    });

    if (Game.clearTarget && this.lastTargetPos != null) {
      Position last = this.lastTargetPos;
      Rect rect = this.getTargetBoundingRect(last);
      this.clearDirtyRect(rect);
      Game.clearTarget = false;
    }
  }

  Rect getEntityBoundingRect(Entity entity) {
    Sprite sprite;

    if (entity is Player && entity.hasWeapon()) {
      sprite = Game.sprites[Types.getKindAsString(entity.weapon)];
    } else {
      sprite = Game.sprites[entity.getSpriteName()];
    }

    return new Rect(
      (entity.x + sprite.offsetX - this.camera.x) * this.scale,
      (entity.y + sprite.offsetY - this.camera.y) * this.scale,
      sprite.width * this.scale,
      sprite.height * this.scale
    );
  }

  Rect getTileBoundingRect(AnimatedTile tile) {
    return new Rect(
      ((getX(tile.index + 1, Game.map.width) * this.tilesize) - this.camera.x) * this.scale,
      (((tile.index / Game.map.width).floor() * this.tilesize) - this.camera.y) * this.scale,
      this.tilesize * this.scale,
      this.tilesize * this.scale
    );
  }

  Rect getTargetBoundingRect([Position pos]) {
    if (pos == null) {
      pos = Game.selected;
    }

    return new Rect(
      ((pos.x * this.tilesize) - this.camera.x) * this.scale,
      ((pos.y * this.tilesize) - this.camera.y) * this.scale,
      this.tilesize * this.scale,
      this.tilesize * this.scale
    );
  }

  void drawEntityName(Entity entity) {
    String name = entity.name;
    if (this.isDebugInfoVisible) {
      name = "${name} (${entity.id},${entity.distanceTo(Game.player)})";
    }

    this.context.save();

    String color = "white";
    if (entity.id == Game.player.id) {
      color = "#fcda5c";
    } else if (Game.player.target != null && entity.id == Game.player.target.id) {
      color = "#40f022";
    } else if (Game.player.isHostile(entity)) {
      color = "#f03a51";
    }

    int nameOffsetY = entity.nameOffsetY;
    if (entity is Player && entity.guild != null) {
      nameOffsetY -= 6;
    }

    this.drawText(
      name, 
      new Position((entity.x + 8) * this.scale, (entity.y + nameOffsetY) * this.scale),
      true,
      color
    );

    if (entity is Player && entity.guild != null) {
      this.setFontSize(9);
      String guildName = entity.guild.name;
      this.drawText(
        guildName, 
        new Position(
          (entity.x + 8) * this.scale, 
          (entity.y + nameOffsetY + 6) * this.scale
        ),
        true,
        "white");
    }

    this.context.restore();
  }

  void drawTerrain() {
    var tilesetwidth = this.tileset.width / Game.map.tilesize;
    Game.forEachVisibleTile((int id, int index) {
      if (!Game.map.isHighTile(id) && !Game.map.isAnimatedTile(id)) { // Don't draw unnecessary tiles
        this.drawTile(this.background, id, this.tileset, tilesetwidth, Game.map.width, index);
      }
    }, 1);
  }

  void drawAnimatedTiles([bool dirtyOnly = false]) {
    var tilesetwidth = this.tileset.width / Game.map.tilesize;

    this.animatedTileCount = 0;
    Game.forEachAnimatedTile((AnimatedTile tile) {
      if (dirtyOnly) {
        if (tile.isDirty) {
          this.drawTile(this.context, tile.id, this.tileset, tilesetwidth, Game.map.width, tile.index);
          tile.isDirty = false;
        }
      } else {
        this.drawTile(this.context, tile.id, this.tileset, tilesetwidth, Game.map.width, tile.index);
        this.animatedTileCount++;
      }
    });
  }

  void drawDirtyAnimatedTiles() {
    this.drawAnimatedTiles(true);
  }

  void drawHighTiles(html.CanvasRenderingContext2D ctx) {
    var tilesetwidth = this.tileset.width / Game.map.tilesize;

    this.highTileCount = 0;
    Game.forEachVisibleTile((int id, int index) {
      if (Game.map.isHighTile(id)) {
        this.drawTile(ctx, id, this.tileset, tilesetwidth, Game.map.width, index);
        this.highTileCount++;
      }
    }, 1);
  }

  void drawBackground(html.CanvasRenderingContext2D ctx, String color) {
    ctx.fillStyle = color;
    ctx.fillRect(0, 0, this.canvas.width, this.canvas.height);
  }

  void drawChat() {
    // @TODO: move to a proper config
    bool showTimestamp = false;
    Map<String, String> colors = {
      "global": "orange",
      "party": "cyan",
      "guild": "#1eff00",
      "say": "white",
      "yell": "red",
      "error": "#f2db2c",
      "notice": "#f2db2c"
    };
    Map<String, String> channelNamePrefix = {
      "global": "[General] ",
      "party": "[Party] ",
      "guild": "[Guild] ",
      "say": "",
      "yell": "",
      "error": "",
      "notice": ""
    };
    Map<String, String> channelNamePostfix = {
      "global": "",
      "party": "",
      "guild": "",
      "say": " says",
      "yell": " yells",
      "error": "",
      "notice": ""
    };

    List<ChatMessage> messages = Game.client.chat.getMessages();
    int line_height = 22;
    int start_offset = -110;

    int i = 0;
    for (final message in messages) {
      String timestamp = showTimestamp ? "[${message.getTimestamp()}] " : "";
      String channel = message.channel;

      if (channel == "error" || channel == "notice") {
        this.drawText(
          "${timestamp}${message.text}",
          new Position(10, start_offset + (i * line_height)), 
          /* centered */ false, 
          colors[channel]
        );
      } else {
        this.drawText(
          "${timestamp}${channelNamePrefix[channel]}[${message.name}]${channelNamePostfix[channel]}: ${message.text}", 
          new Position(10, start_offset + (i * line_height)), 
          /* centered */ false, 
          colors[channel]
        );
      }

      i++;
    }
  }

  void drawParty() {
    if (Game.player.party == null) {
      return;
    }

    Party party = Game.player.party;
    var members = party.getMembers();
    int line_height = 22;
    int start_offset = 200;
    this.drawText("Party:", new Position(10, start_offset), false);
    var i = 1;
    for (final member in members) {
      bool isLeader = party.getLeader() == member;
      String namePostfix = " - ${member.getHealthPercent}% (${member.gridX}, ${member.gridY})"; 
      this.drawText(
        "${i}. ${(isLeader ? "\u2694 " : "")} ${member.name} ${namePostfix}", 
        new Position(10, start_offset + (i * line_height)), 
        /* centered */ false
      );
      i++;
    }
  }

  void drawFPS() {
    DateTime nowTime = new DateTime.now();
    int diffTime = nowTime.millisecond - this.lastTime.millisecond;

    if (diffTime >= 1000) {
      this.realFPS = this.frameCount;
      this.frameCount = 0;
      this.lastTime = nowTime;
    }

    this.frameCount++;
    this.drawText("FPS: ${this.realFPS}", const Position(30, 30), false);
  }

  void drawDebugInfo() {
    if (this.isDebugInfoVisible) {
      this.drawFPS();
      this.drawText("A: ${this.animatedTileCount}", const Position(100, 30), false);
      this.drawText("H: ${this.highTileCount}", const Position(140, 30), false);
    }
  }

  void drawMapInfo() {
    if (Game.player == null) {
      return;
    }

    Player player = Game.player;
    this.drawText(
      "${player.areaName} ${player.gridPosition}", 
      const Position(-1, 20), 
      false, 
      "white",
      "#373737", 
      "right"
    );
  }

  void drawCombatInfo() {
    switch (this.scale) {
      case 2:
        this.setFontSize(20);
        break;
      case 3:
        this.setFontSize(30);
        break;
    }

    Game.infoManager.forEachInfo((Info info) {
      this.context.save();
      this.context.globalAlpha = info.opacity;
      this.drawText(
        info.value, 
        new Position((info.x + 8) * this.scale, (info.y * this.scale).floor()), 
        true, 
        info.fillColor, 
        info.strokeColor
      );
      this.context.restore();
    });

    this.initFont();
  }

  void setCameraView(html.CanvasRenderingContext2D ctx) {
    ctx.translate(-this.camera.x * this.scale, -this.camera.y * this.scale);
  }

  void clearScreen(html.CanvasRenderingContext2D ctx) {
    ctx.clearRect(0, 0, this.canvas.width, this.canvas.height);
  }

  // TODO: keep re-factoring after this
  String getPlayerImage() {
    html.CanvasElement canvas = html.document.createElement('canvas');
    html.CanvasRenderingContext2D ctx = canvas.getContext('2d');
    int os = this.upscaledRendering ? 1 : this.scale;
    Player player = Game.player;
    Sprite sprite = Game.sprites[Types.getKindAsString(Game.player.armor)];
    Animation spriteAnim = sprite.animationData["idle_down"];
    
    // character
    int row = spriteAnim.row;
    int w = sprite.width * os;
    int h = sprite.height * os;
    int y = row * h;
    
    // weapon
    Sprite weapon = Game.sprites[Types.getKindAsString(Game.player.weapon)];
    int ww = weapon.width * os;
    int wh = weapon.height * os;
    int wy = wh * row;
    int offsetX = (weapon.offsetX - sprite.offsetX) * os;
    int offsetY = (weapon.offsetY - sprite.offsetY) * os;
    
    // shadow
    Sprite shadow = Game.shadows["small"];
    int sw = shadow.width * os;
    int sh = shadow.height * os;
    int ox = -sprite.offsetX * os;
    int oy = -sprite.offsetY * os;

    canvas.width = w;
    canvas.height = h;

    ctx.clearRect(0, 0, w, h);
    ctx.drawImageScaledFromSource(shadow.image, 0, 0, sw, sh, ox, oy, sw, sh);
    ctx.drawImageScaledFromSource(sprite.image, 0, y, w, h, 0, 0, w, h);
    ctx.drawImageScaledFromSource(weapon.image, 0, wy, ww, wh, offsetX, offsetY, ww, wh);

    return canvas.toDataUrl("image/png");
  }

  void renderStaticCanvases() {
    this.background.save();
    this.setCameraView(this.background);
    this.drawTerrain();
    this.background.restore();

    if (this.mobile || this.tablet) {
      this.clearScreen(this.foreground);
      this.foreground.save();
      this.setCameraView(this.foreground);
      this.drawHighTiles(this.foreground);
      this.foreground.restore();
    }
  }

  void renderFrame() {
    if (this.mobile || this.tablet) {
      this.renderFrameMobile();
    } else {
      this.renderFrameDesktop();
    }
  }

  void renderFrameDesktop() {
    this.clearScreen(this.context);

    this.context.save();
    this.setCameraView(this.context);
    this.drawAnimatedTiles();

    if (Game.started) {
      this.drawSelectedCell();
      this.drawTargetCell();
    }

    //this.drawOccupiedCells();
    this.drawPathingCells();
    this.drawEntities();
    this.drawCombatInfo();
    this.drawHighTiles(this.context);
    this.context.restore();

    // Overlay UI elements
    // NOTE: keep the order, as this defines the layers of the frame.
    // for example, drawing the cursor should happen last so it appears above all UI elements.
    this.drawMapInfo();
    this.drawDebugInfo();
    this.drawChat();
    this.drawParty();

    this.drawCursor();
  }

  void renderFrameMobile() {
    this.clearDirtyRects();
    this.preventFlickeringBug();

    this.context.save();
    this.setCameraView(this.context);

    this.drawDirtyAnimatedTiles();
    this.drawSelectedCell();
    this.drawDirtyEntities();
    this.context.restore();
  }

  void preventFlickeringBug() {
    this.fixFlickeringTimer.update(Game.currentTime);
  }
}
