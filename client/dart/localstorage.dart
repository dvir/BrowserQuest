library localstorage;

import "dart:convert";
import "dart:html" as html;

import "achievements.dart";
import "base.dart";
import "player.dart";
import "lib/gametypes.dart";

// TODO(#15): move stats storage to the server side. 
// name can probably be the only remaining field, and the rest can be pulled from the server.
class LocalStorage extends Base {

  html.Storage storage = html.window.localStorage;
  Map<String, dynamic> data = {};
  JsonCodec codec;

  LocalStorage() {
    this.codec = new JsonCodec.withReviver(this.reviver);

    if (this.storage.containsKey("data")) {
      this.load(this.codec.decode(this.storage["data"]));
    } else {
      this.reset();
    }
  }

  dynamic reviver(dynamic key, dynamic value) {
    if (key == "armor" || key == "weapon") {
      return Entities.get(value);
    }

    if (key == "unlocked") {
      return value.map((int id) => Achievement.getByID(id)).toList();
    }

    return value;
  }

  dynamic toEncodableImpl(dynamic v) {
    if (v is EntityKind) {
      return v.index;
    }

    if (v is Achievement) {
      return v.id;
    }

    return v;
  }

  void save() {
    this.storage["data"] = this.codec.encode(this.data, toEncodable: this.toEncodableImpl); 
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

  bool get isMusicMuted => this.data["isMusicMuted"] == null ? false : this.data["isMusicMuted"];
  void set isMusicMuted(bool muted) {
    this.data["isMusicMuted"] = muted;
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

  EntityKind get armor => Entities.get(this.data["player"]["armor"]);
  void set armor(EntityKind armor) { 
    this.data["player"]["armor"] = armor; 
    this.save(); 
  }

  EntityKind get weapon => Entities.get(this.data["player"]["weapon"]);
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
    this.data["kills"].forEach((String kindString, int kills) {
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

  int getAchievementCount() => this.data["achievements"]["unlocked"].length;

  bool hasUnlockedAchievement(Achievement achievement) => 
    this.data["achievements"]["unlocked"].contains(achievement); 

  bool unlockAchievement(Achievement achievement) {
    if (this.hasUnlockedAchievement(achievement)) {
      // already unlocked this achievement, don't report it as unlocked again
      return false;
    }

    this.data["achievements"]["unlocked"].add(achievement);
    this.save();
    return true;
  }
}
