library localstorage;

import "dart:convert";
import "dart:html" as html;

import "base.dart";
import "game.dart";
import "player.dart";
import "lib/gametypes.dart";

// TODO(to-server-side): move stats storage to the server side. 
// name can probably be the only remaining field, and the rest can be pulled from the server.
class LocalStorage extends Base {

  html.Storage storage = html.window.localStorage;
  Map<String, dynamic> data = {};
  JsonCodec codec;

  LocalStorage() {
    this.codec = new JsonCodec(
      reviver: (dynamic key, dynamic value) {
      if (key == "armor" || key == "weapon") {
        return Entities.get(value);
      }

      return value;
      },
      toEncodable: (dynamic v) {
        if (v is EntityKind) {
          return v.index;
        }

        return v;
      }); 

    if (this.storage.containsKey("data")) {
      this.load(JSON.decode(this.storage["data"]));
    } else {
      this.reset();
    }
  }

  void save() {
    this.storage["data"] = this.codec.encode(this.data); 
  }

  void load(data) {
    this.data = data;
  }

  void reset() {
    this.data["hasAlreadyPlayed"] = false;
    this.data["player"] = {
      "name": "",
      "level": 1,
      "image": "",
      "armor": null,
      "weapon": null
    };
    this.data["achievements"] = {
      "unlocked": [],
      "totalDmg": 0,
      "totalRevives": 0
    };
    this.data["kills"] = {};

    this.save();
  }

  bool get hasAlreadyPlayed => this.data["hasAlreadyPlayed"];
  void set hasAlreadyPlayed(bool played) {
    this.data["hasAlreadyPlayed"] = played;
    this.save(); 
  }

  String get name => this.data["player"]["name"];
  void set name(String name) { 
    this.data["player"]["name"] = name; 
    this.save(); 
  }

  int get level => this.data["player"]["level"];
  void set level(int level) { 
    this.data["player"]["level"] = level; 
    this.save(); 
  }

  EntityKind get armor => this.data["player"]["armor"];
  void set armor(EntityKind armor) { 
    this.data["player"]["armor"] = armor; 
    this.save(); 
  }

  EntityKind get weapon => this.data["player"]["weapon"];
  void set weapon(EntityKind weapon) { 
    this.data["player"]["weapon"] = weapon; 
    this.save(); 
  }

  String get image => this.data["player"]["image"];
  void set image(String image) { 
    this.data["player"]["image"] = image; 
    this.save(); 
  }

  int get totalDamageTaken => this.data["achievements"]["totalDmg"];
  void set totalDamageTaken(int dmg) { 
    this.data["achievements"]["totalDmg"] = dmg;
    this.save();
  }

  int get totalKills {
    int total = 0;
    this.data["kills"].forEach((EntityKind kind, int kills) {
      total += kills;
    });

    return total;
  }

  int get totalRevives => this.data["achievements"]["totalRevives"];
  void set totalRevives(int revives) { 
    this.data["achievements"]["totalRevives"] = revives;
    this.save();
  }

  void initPlayer(Player player) {
    this.hasAlreadyPlayed = true;
    this.updatePlayer(player);

    void updateAndSavePlayer() { 
      this.savePlayer(Game.renderer.getPlayerImage(player), player);
    };
    player.onExclusive(this, "LevelChange", updateAndSavePlayer);
    player.onExclusive(this, "ArmorChange", updateAndSavePlayer);
    player.onExclusive(this, "WeaponChange", updateAndSavePlayer);
  }

  void savePlayer(String image, Player player) {
    this.data["player"]["image"] = image;
    this.updatePlayer(player);
  }

  void updatePlayer(Player player) {
    this.data["player"]["name"] = player.name;
    this.data["player"]["armor"] = player.armor;
    this.data["player"]["weapon"] = player.weapon;
    this.data["player"]["level"] = player.level;
    this.save();
  }

  void addDamage(int damage) {
    this.totalDamageTaken += damage;
  }

  void incrementRevives() {
    this.totalRevives++;
  }

  void recordKill(EntityKind kind) {
    if (this.data["kills"].containsKey(kind.toString())) {
      this.data["kills"][kind.toString()]++;
      return;
    } 

    this.data["kills"][kind.toString()] = 1;

    this.save();
  }

  int getKillCount(EntityKind kind) {
    return this.data["kills"].containsKey(kind.toString()) ? this.data["kills"][kind.toString()] : 0;
  }

  int getAchievementCount() => this.data["achievements"].unlocked.length;

  bool hasUnlockedAchievement(int id) => 
    this.data["achievements"]["unlocked"].contains(id); 

  bool unlockAchievement(int id) {
    if (this.hasUnlockedAchievement(id)) {
      // already unlocked this achievement, don't report it as unlocked again
      return false;
    }

    this.data["achievements"]["unlocked"].add(id);
    this.save();
    return true;
  }
}
