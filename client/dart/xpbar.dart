library xpbar;

import 'dart:html' hide Player;

import 'player.dart';
import 'progressbar.dart';

class XPBar extends ProgressBar {

  Player player;

  XPBar(Player this.player, Element $container, Element $bar, $progress): super($container, $bar, $progress) {
    this.player.on("XPChange", () {
      this.update();
    });
  }

  int getAmount() {
    return this.player.xp;
  }

  int getTotal() {
    return this.player.maxXP;
  }
}
