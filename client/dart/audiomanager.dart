library audiomanager;

import "dart:html";
import "dart:web_audio";

import "audio.dart";
import "area.dart";
import "base.dart";
import "entity.dart";
import "game.dart";

class AudioManager extends Base {

  bool enabled = true;
  List<Area> areas = [];
  static final List<String> musicNames = const ["village", "beach", "forest", "cave", "desert", "lavaland", "boss"];
  static final List<String> soundNames = const ["loot", "hit1", "hit2", "hurt", "heal", "chat", "revive", "death", "firefox", "achievement", "kill1", "kill2", "noloot", "teleport", "chest", "npc", "npc-end"];
  Map<String, Audio> sounds = {};
  Map<String, Audio> musics = {};
  AudioContext audioContext;
  GainNode gainNode;
  Audio currentMusic;
  Audio queuedMusic;

  AudioManager({void onLoaded()}) {
    this.audioContext = new AudioContext();
    this.gainNode = this.audioContext.createGain();
    this.gainNode.connectNode(this.audioContext.destination, 0, 0);

    this.on("Loaded", onLoaded);
    this.onMulti(["SoundLoaded", "MusicLoaded"], () {
      if (this.isLoaded) {
        this.trigger("Loaded");
      }
    });

    AudioManager.soundNames.forEach((String name) {
      Sound sound = new Sound(this.audioContext, this.gainNode, name);
      sound.load(() {
        this.sounds[name] = sound;
        if (this.hasSoundLoaded) {
          this.trigger("SoundLoaded");
        }
      });
    });

    AudioManager.musicNames.forEach((String name) {
      Music music = new Music(this.audioContext, this.gainNode, name);
      music.load(() {
        this.musics[name] = music;
        if (this.hasMusicLoaded) {
          this.trigger("MusicLoaded");
        }
      });
    });
  }

  Audio getSound(String name) {
    return this.sounds[name];
  }

  Audio getMusic(String name) {
    return this.musics[name];
  }

  bool get hasSoundLoaded => this.sounds.length == AudioManager.soundNames.length;
  bool get hasMusicLoaded => this.musics.length == AudioManager.musicNames.length;
  bool get isLoaded => this.hasSoundLoaded && this.hasMusicLoaded;

  void updateMusicWhenLoaded() {
    if (this.hasMusicLoaded) {
      this.updateMusic();
      return;
    }

    this.on("MusicLoaded", this.updateMusic);
  }

  void playSound(String name) {
    if (!this.enabled) {
      // sound is disabled
      return;
    }

    if (!this.sounds.containsKey(name)) {
      window.console.error("Cannot play '${name}' before it's loaded.");
      return;
    }
    this.sounds[name].play();
  }

  void playMusic(String name) {
    if (!this.enabled) {
      // sound is disabled
      return;
    }

    if (this.isCurrentMusic(this.musics[name])) {
      // it's already the current music
      return;
    }

    if (this.currentMusic == null) {
      this.startMusic(this.musics[name]);
      return;
    }

    this.queueMusic(this.musics[name]);
    this.currentMusic.fadeOut(() {
      this.currentMusic = null;

      if (this.queuedMusic != null) {
        this.startMusic(this.queuedMusic);
        this.clearQueuedMusic();
      }
    });
  }

  void queueMusic(Music music) {
    this.queuedMusic = music;
  }

  void clearQueuedMusic() {
    this.queuedMusic = null;
  }

  void startMusic(Music music) {
    this.currentMusic = music;
    this.currentMusic.fadeIn();
  }
  
  void toggle() {
    this.enabled = !this.enabled;
    if (this.enabled) {
      this.currentMusic = null;
      this.updateMusic();
      return;
    }
    
    this.resetMusic();
  }

  void resetMusic() {
    if (this.currentMusic == null) {
      return;
    }
    
    this.currentMusic.stop();
  }

  void addArea(Map<String, dynamic> data) {
    Area area = new Area(data["x"], data["y"], data["w"], data["h"], data["id"]);
    this.areas.add(area);
  }

  Audio getSurroundingMusic(Entity entity) {
    for (final area in this.areas) {
      if (area.contains(entity)) {
        return this.getMusic(area.musicName);
      }
    }

    return null;
  }

  void updateMusic() {
    if (!this.enabled) {
      // sound is disabled
      return;
    }

    Audio music = this.getSurroundingMusic(Game.player);
    if (music == null) {
      // no music found for the area the player is in
      this.fadeOutCurrentMusic();
      return;
    }

    if (this.isCurrentMusic(music)) {
      // it's already the current music
      return;
    }

    this.fadeOutCurrentMusic(() {
      this.playMusic(music.name);
    });
  }

  bool isCurrentMusic(Music music) => (this.currentMusic == music);

  void fadeOutCurrentMusic([void callback()]) {
    if (this.currentMusic == null) {
      // there is no current music to fade out.
      if (callback != null) {
        callback();
      }
      return;
    }

    this.currentMusic.fadeOut(() {
      this.currentMusic = null;
      if (callback != null) {
        callback();
      }
    }); 
  }
}
