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

  AudioManager() {
    this.audioContext = new AudioContext();
    this.gainNode = this.audioContext.createGain();
    this.gainNode.connectNode(this.audioContext.destination, 0, 0);

    AudioManager.soundNames.forEach((String name) {
      var sound = new Sound(this.audioContext, this.gainNode, name);
      sound.load(() {
        this.sounds[name] = sound;
      });
    });

/*
    AudioManager.musicNames.forEach((String name) {
      var music = new Music(this.audioContext, this.gainNode, name);
      music.load(() {
        this.musics[name] = music;
      });
    });
*/
  }

  Audio getSound(String name) {
    return this.sounds[name];
  }

  Audio getMusic(String name) {
    return this.musics[name];
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

    Music music = this.musics[name];
    if (music.isFadingOut) {
      music.fadeIn();
    } else {
      music.play();
    }

    this.currentMusic = music;
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

  void addArea(var data) {
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

    this.fadeOutCurrentMusic();
    this.playMusic(music.name);
  }

  bool isCurrentMusic(Music music) => (this.currentMusic == music);

  void fadeOutCurrentMusic() {
    if (this.currentMusic == null) {
      // there is no current music to fade out.
      return;
    }

    this.currentMusic.fadeOut(() {
      this.currentMusic = null;
    });
  }
}
