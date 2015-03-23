library sprite;

import "dart:html" as html;
import "dart:typed_data";

import "animation.dart";
import "base.dart";
import "position.dart";

import "../sprites/all_sprites.dart";

class Sprite extends Base {

  // public
  String id;
  String name;
  String filepath;
  int scale;
  int offsetX = 0;
  int offsetY = 0;
  int width;
  int height;
  html.ImageElement image;
  Map<String, Map<String, int>> animationData;
  Sprite _whiteSprite;
  Sprite _silhouetteSprite;

  // private
  bool _isLoaded = false;

  Sprite(
    html.ImageElement this.image,
    bool isLoaded,
    int this.offsetX,
    int this.offsetY,
    int this.width,
    int this.height
  ) {
    this._isLoaded = isLoaded;
  }

  Sprite.FromJSON(String this.name, int this.scale) {
    dynamic data = (new RawSprites()).get(name);
    if (data == null) {
      throw new Exception('Sprite ${this.name} is missing from sprites map!');
    }

    this.id = data["id"];
    StringBuffer sb = new StringBuffer();
    sb.write("img/");
    sb.write(this.scale);
    sb.write("/");
    sb.write(this.id);
    sb.write(".png");
    this.filepath = sb.toString();
    this.animationData = data["animations"];
    this.width = data["width"];
    this.height = data["height"];
    this.offsetX = data["offset_x"] != null ? data["offset_x"] : -16;
    this.offsetY = data["offset_y"] != null ? data["offset_y"] : -16;

    this.load();
  }

  bool get isLoaded => _isLoaded;
  void set isLoaded(bool isLoaded) {
    this._isLoaded = isLoaded;
    this.trigger(isLoaded ? "Load" : "Unload");
  }

  void load() {
    this.image = new html.ImageElement();
    this.image.src = this.filepath;
    this.image.onLoad.listen((e) {
      this.isLoaded = true;
    });
  }

  Map<String, Animation> createAnimations() {
    Map<String, Animation> animations = new Map<String, Animation>();

    for (String name in this.animationData.keys) {
      Map<String, int> a = this.animationData[name];
      Animation animation =
        new Animation(name, a['length'], a['row'], this.width, this.height);
      animations.putIfAbsent(name, () => animation);
    }

    return animations;
  }

  void createHurtSprite() {
    if (!this.isLoaded) return;

    html.CanvasElement canvas = new html.CanvasElement(width: this.image.width, height: this.image.height);
    html.CanvasRenderingContext2D ctx = canvas.getContext('2d');
    int width = this.image.width;
    int height = this.image.height;
    ctx.drawImageScaled(this.image, 0, 0, width, height);
    html.ImageData spriteData = ctx.getImageData(0, 0, width, height);

    for (int i = 0; i < spriteData.data.length; i += 4) {
      spriteData.data[i] = 255;
      spriteData.data[i + 1] = spriteData.data[i + 2] = 75;
    }

    ctx.putImageData(spriteData, 0, 0);

    html.ImageElement image = new html.ImageElement(src: canvas.toDataUrl()); 
    this._whiteSprite = new Sprite(
      image,
      true,
      this.offsetX,
      this.offsetY,
      this.width,
      this.height
    );
  }

  Sprite getHurtSprite() {
    return this._whiteSprite;
  }

  void createSilhouette() {
    if (!this.isLoaded) return;

    html.CanvasElement canvas = new html.CanvasElement(width: this.image.width, height: this.image.height);
    html.CanvasRenderingContext2D ctx = canvas.getContext('2d');
    int width = this.image.width;
    int height = this.image.height;
    ctx.drawImageScaled(this.image, 0, 0, width, height);
    html.ImageData finalData = ctx.getImageData(0, 0, width, height);
    Uint8ClampedList data = ctx.getImageData(0, 0, width, height).data;

    int getIndex(int x, int y) {
      return ((width * (y - 1)) + x - 1) * 4;
    };

    Position getPosition(int i) {
      int x;
      int y;

      i = (i / 4).floor() + 1;
      x = i % width;
      y = ((i - x) / width).floor() + 1;

      return new Position(x, y);
    };

    bool isBlankPixel(int i) {
      if (i < 0 || i >= data.length) {
        return true;
      }
      return data[i] == 0
             && data[i + 1] == 0
             && data[i + 2] == 0
             && data[i + 3] == 0;
    };

    hasAdjacentPixel(i) {
      Position pos = getPosition(i);
      return (pos.x < width && !isBlankPixel(getIndex(pos.x + 1, pos.y)))
             || (pos.x > 1 && !isBlankPixel(getIndex(pos.x - 1, pos.y)))
             || (pos.y < height && !isBlankPixel(getIndex(pos.x, pos.y + 1)))
             || (pos.y > 1 && !isBlankPixel(getIndex(pos.x, pos.y - 1)));
    };

    for (int i = 0; i < data.length; i += 4) {
      if (isBlankPixel(i) && hasAdjacentPixel(i)) {
        finalData.data[i] = finalData.data[i + 1] = 255;
        finalData.data[i + 2] = 150;
        finalData.data[i + 3] = 150;
      }
    }

    ctx.putImageData(finalData, 0, 0);
    html.ImageElement image = new html.ImageElement(src: canvas.toDataUrl()); 
    this._silhouetteSprite = new Sprite(
      image,
      true,
      this.offsetX,
      this.offsetY,
      this.width,
      this.height
    );
  }

  Sprite getSilhouetteSprite() {
    return this._silhouetteSprite;
  }
}
