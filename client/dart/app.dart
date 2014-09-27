library app;

import 'dart:html';

import 'base.dart';
import 'game.dart';
import 'entity.dart';
import 'player.dart';
import 'healthbar.dart';

class Config {
  String host = "localhost";
  int port = 8000;
  bool dispatcher = true;
}

class Application extends Base {

  Config config = new Config();

  void playerDeath() {
    Element body = document.querySelector('body');
    body.classes.remove('credits');
    body.classes.add('death');
  }

  void playerInvincible(bool state) {
    document.querySelector('#player > .hitpoints').classes.toggle('invincible', state);
  }

  // TODO: implement
  void initEquipmentIcons() {
    window.console.log("initEquipmentIcons");
  }

  // TODO: implement
  void showMessage(String message) {
    window.console.log("Notification: $message");
  }

  // TODO: implement or remove. the relevant code is complicated
  void updateInventory() {}
  void updateSkillbar() {}

  void disconnected(String message) {
    document.querySelector('#death p').innerHtml = "${message} <em>Please reload the page.</em>";
    document.querySelector('#respawn').style.display = 'none';
  }

  void initBars() {
    this.initEquipmentIcons();
    this.initHealthBar();
    this.initXPBar();
    this.initTargetBar();
  }

  void initHealthBar() {
    int scale = Game.renderer.getScaleFactor();
    Healthbar healthbar = new Healthbar(document.querySelector("#player"), Game.player, scale);

    Game.events.on("HealthChange", () {
      healthbar.update();
    });
  }

  void initXPBar() {
    Game.events.on("XPChange", () {
      int scale = Game.renderer.getScaleFactor();
      int XPMaxWidth = int.parse(document.querySelector("#xpbar").style.width) - (12 * scale);
      Player player = Game.player;

      int barWidth = ((XPMaxWidth / player.maxXP) * (player.xp > 0 ? player.xp : 0)).round();
      document.querySelector("#xpbar").innerHtml = "${player.xp}/${player.maxXP}";
      document.querySelector("#xp").style.width = "${barWidth}px";
      document.querySelector("#level").innerHtml = player.level.toString();
    });
  }

  void initTargetBar() {
    Element $target = document.querySelector("#target");

    Game.events.on("TargetChange", () {
      int scale = Game.renderer.getScaleFactor();
      Entity target = Game.player.target;

      if (target == null) {
        $target.style.display = 'none';
        return;
      }

      $target.style.display = 'block';
      Healthbar healthbar = new Healthbar($target, target, scale);
      target.on("change", () {
        healthbar.update();
      });
    });
  }
}
