library localstorage;

import "dart:convert";
import "dart:html" as html;

import "base.dart";
import "player.dart";
import "lib/gametypes.dart";

class LocalStorage extends Base {

  html.Storage storage = html.window.localStorage;
  var data;

  LocalStorage() {
    if (this.storage.containsKey("data")) {
      this.load(JSON.decode(this.storage["data"]));
    } else {
      this.reset();
    }
  }

  void save() {
    this.storage["data"] = JSON.encode(this.data); 
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
      "totalKills": 0,
      "totalDmg": 0,
      "totalRevives": 0
    };
    this.data["kills"] = {};

    this.save();
  }

  bool get hasAlreadyPlayed => this.data["hasAlreadyPlayed"];
  void set hasAlreadyPlayed(bool played) {
    this.data["hasAlreadyPlayed"] = played;
  }

  String get name => this.data["player"].name;
  void set name(String name) { this.data["player"].name = name; }

  int get level => this.data["player"].level;
  void set level(int level) { this.data["player"].level = level; }

  Entities get armor => this.data["player"].armor;
  void set armor(Entities armor) { this.data["player"].armor = armor; }

  Entities get weapon => this.data["player"].weapon;
  void set weapon(Entities weapon) { this.data["player"].weapon = weapon; }

  String get image => this.data["player"].image;
  void set image(String image) { this.data["player"].image = image; }

  int get totalDamageTaken => this.data["achievements"].totalDmg;
  void set totalDamageTaken(int dmg) { 
    this.data["achievements"].totalDmg = dmg;
  }

  int get totalKills => this.data["achievements"].totalKills;
  void set totalKills(int kills) { 
    this.data["achievements"].totalKills = kills;
  }

  int get totalRevives => this.data["achievements"].totalRevives;
  void set totalRevives(int revives) { 
    this.data["achievements"].totalRevives = revives;
  }

  void initPlayer(Player player) {
    this.hasAlreadyPlayed = true;
    this.updatePlayer(player);
  }

  void savePlayer(String image, Player player) {
    this.image = image;
    this.updatePlayer(player);
  }

  void updatePlayer(Player player) {
    this.name = player.name;
    this.armor = player.armor;
    this.weapon = player.weapon;
    this.level = player.level;
  }

  void addDamage(int damage) {
    this.totalDamageTaken += damage;
  }

  void incrementTotalKills() {
    this.totalKills++;
  }
  
  void incrementRevives() {
    this.totalRevives++;
  }

  void recordKill(Entities kind) {
    if (this.data["kills"].containsKey(kind)) {
      this.data["kills"][kind]++;
      return;
    } 

    this.data["kills"][kind] = 0;
  }

  int getKillCount(Entities kind) {
    if (this.data["kills"].containsKey(kind)) {
      return this.data["kills"][kind];
    }

    return 0;
  }

  int getAchievementCount() => this.data["achievements"].unlocked.length;

  bool hasUnlockedAchievement(int id) => 
    this.data["achievements"].unlocked.contains(id); 

  bool unlockAchievement(int id) {
    if (this.hasUnlockedAchievement(id)) {
      // already unlocked this achievement, don't report it as unlocked again
      return false;
    }

    this.data["achievements"].unlocked.add(id);
    return true;
  }
}
