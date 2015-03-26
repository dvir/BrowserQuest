library healthbar;

import 'dart:html' hide Player;

import 'character.dart';
import 'player.dart';
import 'progressbar.dart';

class HealthBar extends ProgressBar {

  Character target;
  Map<String, EventHandler> handlers;

  HealthBar(Element $container, Element $bar, $progress): super($container, $bar, $progress);

  int getAmount() {
    return this.target.hp;
  }

  int getTotal() {
    return this.target.maxHP;
  }

  bool shouldHide() {
    return this.target.hp == 0 
      && !(this.target is Player); 
  }

  void setTarget(Character target) {
    if (this.target == target) {
      // nothing changed
      return;
    }

    // remove old handlers
    if (this.handlers != null && this.target != null) {
      this.target.off(this.handlers);
      this.handlers = null; 
    }

    this.target = target;

    // subscribe to events on the entity
    if (this.target != null) {
      this.handlers = this.target.on("change", () {
        this.update();
      });
    }

    if (this.target == null) {
      this.$container.style.display = 'none'; 
      return;
    }

    this.update();
  }
}
