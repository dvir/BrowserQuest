library sprite;

import "dart:html";

import "base.dart";
import "animation.dart";

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
  ImageElement image;
  var animationData;
  Sprite whiteSprite;
  Sprite silhouetteSprite;

  // private
  bool _isLoaded = false;

  Sprite(
    var image, 
    bool isLoaded, 
    int offsetX, 
    int offsetY, 
    int width, 
    int height
  ) {
    this.image = image;
    this._isLoaded = isLoaded;
    this.offsetX = offsetX;
    this.offsetY = offsetY;
    this.width = width;
    this.height = height;
  }

  Sprite.FromJSON(data) {
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
    this.offsetX = data["offset_x"] ? data["offset_x"] : -16;
    this.offsetY = data["offset_y"] ? data["offset_y"] : -16;

    this.load();
  }

  bool get isLoaded => _isLoaded; 
  void set isLoaded(bool isLoaded) {
    this._isLoaded = isLoaded;
    this.trigger(isLoaded ? "Load" : "Unload");
  }

  void load() {
    this.image = new ImageElement();
    this.image.src = this.filepath;
    this.image.onLoad.listen((e) {
      this.isLoaded = true;
    });
  }

  Map<String, Animation> createAnimations() {
    Map<String, Animation> animations = new Map<String, Animation>();

    for (var name in this.animationData) {
      var a = this.animationData[name];
      Animation animation = 
        new Animation(name, a.length, a.row, this.width, this.height);
      animations.putIfAbsent(name, () => animation);
    }

    return animations;
  }

  void createHurtSprite() {
    if (!this.isLoaded) return;

    CanvasElement canvas = new CanvasElement();
    var ctx = canvas.getContext('2d');
    int width = this.image.width;
    int height = this.image.height;
    var spriteData, data;

    canvas.width = width;
    canvas.height = height;
    ctx.drawImage(this.image, 0, 0, width, height);
    try {
      spriteData = ctx.getImageData(0, 0, width, height);

      data = spriteData.data;

      for (var i = 0; i < data.length; i += 4) {
        data[i] = 255;
        data[i + 1] = data[i + 2] = 75;
      }
      spriteData.data = data;

      ctx.putImageData(spriteData, 0, 0);

      this.whiteSprite = new Sprite(
        canvas, 
        true, 
        this.offsetX, 
        this.offsetY, 
        this.width, 
        this.height
      );
    } catch (e) {
      window.console.error("Error getting image data for sprite : " + this.name);
      window.console.error(e);
    }
  }

  Sprite getHurtSprite() {
    return this.whiteSprite;
  }

  void createSilhouette() {
    CanvasElement canvas = new CanvasElement();
    var ctx = canvas.getContext('2d');
    int width = this.image.width;
    int height = this.image.height;
    var spriteData, data;
    var finalData, fdata;

    canvas.width = width;
    canvas.height = height;
    ctx.drawImage(this.image, 0, 0, width, height);
    data = ctx.getImageData(0, 0, width, height).data;
    finalData = ctx.getImageData(0, 0, width, height);
    fdata = finalData.data;

    getIndex(x, y) {
      return ((width * (y - 1)) + x - 1) * 4;
    };

    getPosition(i) {
      var x, y;

      i = (i / 4) + 1;
      x = i % width;
      y = ((i - x) / width) + 1;

      return {
        x: x,
        y: y
      };
    };

    isBlankPixel(i) {
      if (i < 0 || i >= data.length) {
        return true;
      }
      return data[i] == 0 
             && data[i + 1] == 0 
             && data[i + 2] == 0 
             && data[i + 3] == 0;
    };

    hasAdjacentPixel(i) {
      var pos = getPosition(i);
      return (pos["x"] < width && !isBlankPixel(getIndex(pos["x"] + 1, pos["y"])))
             || (pos["x"] > 1 && !isBlankPixel(getIndex(pos["x"] - 1, pos["y"]))) 
             || (pos["y"] < height && !isBlankPixel(getIndex(pos["x"], pos["y"] + 1))) 
             || (pos["y"] > 1 && !isBlankPixel(getIndex(pos["x"], pos["y"] - 1))); 
    };

    for (var i = 0; i < data.length; i += 4) {
      if (isBlankPixel(i) && hasAdjacentPixel(i)) {
        fdata[i] = fdata[i + 1] = 255;
        fdata[i + 2] = 150;
        fdata[i + 3] = 150;
      }
    }

    finalData.data = fdata;
    ctx.putImageData(finalData, 0, 0);

    this.silhouetteSprite = new Sprite(
      canvas,
      true,
      this.offsetX,
      this.offsetY,
      this.width,
      this.height
    );
  }
}
