library audio;

import "dart:async";
import "dart:html";
import "dart:math";
import "dart:web_audio";

import "area.dart";
import "base.dart";

class Audio extends Base {
  
  static final String SOUND_PATH = "audio/sounds/";
  static final String MUSIC_PATH = "audio/music/";
  String extension;

  String name;
  String path_prefix = "";
  AudioBuffer buffer;
  AudioBufferSourceNode source;
  AudioContext audioContext;
  GainNode gainNode;
  List<Area> areas = [];
  num volume = 1;

  num _fadeVolume = 1;
  num _fadeStep = 0.02;
  num _fadeSpeed = 50;
  Timer _fadeTimer;
  bool isFadingOut = false;
  bool isFadingIn = false;

  Audio(
    AudioContext this.audioContext, 
    GainNode this.gainNode,
    String this.name, 
    [String this.extension = "ogg"]
  );
  
  void load(Function callback) {
    String path = "${this.path_prefix}${this.name}.${this.extension}";
    HttpRequest request = new HttpRequest();
    request.open("GET", path, async: true);
    request.responseType = "arraybuffer";
    request.onLoad.listen((e) {
      this.audioContext.decodeAudioData(request.response).then((AudioBuffer buffer) {
        if (buffer == null) {
          window.console.error("[Audio] Failed to decode '${path}'");
          return;
        }

        this.initBuffer(buffer);
        if (callback != null) {
          callback();
        }
      });
    });
    request.onError.listen((e) => window.console.error("[Audio] Failed to load '${path}'"));
    request.send();
  }

  // TODO(soundtrack): might need to take care of channels
  void initBuffer(AudioBuffer buffer) {
    this.buffer = buffer;
    this.source = this.audioContext.createBufferSource();
    this.source.buffer = buffer;
    this.source.connectNode(this.gainNode, 0, 0);
  }

  void play() {
    if (this.source == null) {
// TODO(soundtrack): for now, just return instead of crashing
return;
//      throw "Audio ${name} has not been loaded yet";
    }

    this.source.start(0);
  }

  void stop() {
    if (this.source == null) {
// TODO(soundtrack): for now, just return instead of crashing
return;
//      throw "Audio ${name} has not been loaded yet";
    }

    this.source.stop(0);
  }

  void fadeIn([Function callback = null]) {
    this._clearFade();
    this._fadeVolume = 0;
    this.isFadingIn = true;

    this._fadeTimer = new Timer.periodic(new Duration(milliseconds: this._fadeSpeed), (Timer timer) {
      gainNode.gain.value = this._fadeVolume * this._fadeVolume;
      this._fadeVolume = max(this.volume, this._fadeVolume + this._fadeStep);
      if (this._fadeVolume == this.volume) {
        this._clearFade();
        if (callback != null) {
          callback();
        }
      }
    });
  }

  void fadeOut([Function callback = null]) {
    this._clearFade();
    this._fadeVolume = this.volume;
    this.isFadingOut = true;

    this._fadeTimer = new Timer.periodic(new Duration(milliseconds: this._fadeSpeed), (Timer timer) {
      gainNode.gain.value = this._fadeVolume * this._fadeVolume;
      this._fadeVolume = max(0, this._fadeVolume - this._fadeStep);
      if (this._fadeVolume == 0) {
        this._clearFade();
        if (callback != null) {
          callback();
        }
      }
    });
  }

  void _clearFade() {
    if (this._fadeTimer != null && this._fadeTimer.isActive) {
      this._fadeTimer.cancel();
    }

    this.isFadingOut = false;
    this.isFadingIn = false;
  }
}

class Sound extends Audio {

  String path_prefix = Audio.SOUND_PATH;

  Sound(
    AudioContext audioContext, 
    GainNode gainNode, 
    String name, 
    [String extension = "ogg"]
  ): super(audioContext, gainNode, name, extension);
}

class Music extends Audio {

  String path_prefix = Audio.MUSIC_PATH;

  Music(
    AudioContext audioContext, 
    GainNode gainNode, 
    String name, 
    [String extension = "ogg"]
  ): super(audioContext, gainNode, name, extension);

  void initBuffer(AudioBuffer buffer) {
    super.initBuffer(buffer);
    this.source.loop = true;
  }
}
