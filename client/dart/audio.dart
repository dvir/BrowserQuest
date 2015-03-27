library audio;

import "dart:async";
import "dart:html";
import "dart:math";
import "dart:web_audio";

import "area.dart";
import "base.dart";

class Audio extends Base {
  
  String extension;

  String name;
  AudioBuffer buffer;
  AudioBufferSourceNode source;
  AudioContext audioContext;
  GainNode gainNode;
  List<Area> areas = [];
  num volume = 1;

  num _fadeVolume = 0;
  num _fadeStep = 0.02;
  num _fadeSpeed = 50;
  Timer _fadeTimer;
  bool _isPlaying = false;
  bool isFadingOut = false;
  bool isFadingIn = false;

  Audio(
    AudioContext this.audioContext, 
    GainNode this.gainNode,
    String this.name, 
    [String this.extension = "ogg"]
  );

  String get path => "audio/";
  
  void load(Function callback) {
    String path = "${this.path}${this.name}.${this.extension}";
    HttpRequest request = new HttpRequest();
    request.open("GET", path, async: true);
    request.responseType = "arraybuffer";
    request.onLoad.listen((e) {
      this.audioContext.decodeAudioData(request.response).then((AudioBuffer buffer) {
        if (buffer == null) {
          window.console.error("[Audio] Failed to decode '${path}'");
          return;
        }

        this.buffer = buffer;
        this.initBuffer();
        if (callback != null) {
          callback();
        }
      });
    });
    request.onError.listen((e) => window.console.error("[Audio] Failed to load '${path}'"));
    request.send();
  }

  void initBuffer() {
    this.source = this.audioContext.createBufferSource();
    this.source.buffer = buffer;
    this.source.connectNode(this.gainNode, 0, 0);
  }

  void play() {
    if (this.source == null) {
      throw "Audio ${name} has not been loaded yet";
    }

    if (this._isPlaying) {
      this.stop();
    }

    this._isPlaying = true;
    this.source.start(0);
  }

  void stop() {
    if (this.source == null) {
      throw "Audio ${name} has not been loaded yet";
    }

    this.source.stop(0);
    this.initBuffer();
    this._isPlaying = false;
  }

  void _setCurrentGainNodeVolume() {
    this.gainNode.gain.value = this._fadeVolume * this._fadeVolume;
  }

  void fadeIn([Function callback = null]) {
    if (this.isFadingIn) {
      return;
    }

    if (this.isFadingOut) {
      this._clearFadeTimer();
      this.isFadingOut = false;
    } else {
      this._clearFade();
    }

    this.isFadingIn = true;

    if (!this._isPlaying) {
      this.play();
    }
    this._fadeTimer = new Timer.periodic(new Duration(milliseconds: this._fadeSpeed), (Timer timer) {
      this._setCurrentGainNodeVolume();
      this._fadeVolume = min(this.volume, this._fadeVolume + this._fadeStep);
      if (this._fadeVolume == this.volume) {
        this._clearFade();
        if (callback != null) {
          callback();
        }
      }
    });
  }

  void fadeOut([Function callback = null]) {
    if (this.isFadingOut) {
      return;
    }

    if (this.isFadingIn) {
      this._clearFadeTimer();
      this.isFadingIn = false;
    } else {
      this._clearFade();
    }

    this.isFadingOut = true;

    this._fadeTimer = new Timer.periodic(new Duration(milliseconds: this._fadeSpeed), (Timer timer) {
      this._setCurrentGainNodeVolume();
      this._fadeVolume = max(0, this._fadeVolume - this._fadeStep);
      if (this._fadeVolume == 0) {
        this.stop();
        this._clearFade();
        if (callback != null) {
          callback();
        }
      }
    });
  }

  void _clearFadeTimer() {
    if (this._fadeTimer != null && this._fadeTimer.isActive) {
      this._fadeTimer.cancel();
    }
  }

  void _clearFade() {
    this._clearFadeTimer();

    this.isFadingOut = false;
    this.isFadingIn = false;
    this.gainNode.gain.value = 1;
  }
}

class Sound extends Audio {

  Sound(
    AudioContext audioContext, 
    GainNode gainNode, 
    String name, 
    [String extension = "ogg"]
  ): super(audioContext, gainNode, name, extension);

  String get path => "audio/sounds/";
}

class Music extends Audio {

  Music(
    AudioContext audioContext, 
    GainNode gainNode, 
    String name, 
    [String extension = "ogg"]
  ): super(audioContext, gainNode, name, extension);

  String get path => "audio/music/";

  void initBuffer() {
    super.initBuffer();
    this.source.loop = true;
  }
}
