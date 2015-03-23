library healthbar;

import 'dart:html' hide Player;

import 'base.dart';
import 'character.dart';
import 'player.dart';

class HealthBar extends Base {

  Element element;
  Element barContainer;
  Element hpContainer;
  Character target;
  Map<String, EventHandler> handlers;

  HealthBar(Element this.element) {
    this.barContainer = this.element.querySelector(".healthbar");
    this.hpContainer = this.element.querySelector(".hitpoints");
    this.element.style.display = 'none'; 
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
      this.element.style.display = 'none'; 
      return;
    }

    this.update();
  }

  void update() {
    this.element.style.display = 
      this.target.hp == 0 
        && !(this.target is Player) 
      ? 'none' 
      : 'block';
    int barWidth = this.target.maxHP > 0 ? (this.target.hp * 100 / this.target.maxHP).round() : 0;
    this.hpContainer.style.width = "${barWidth}%";
    this.barContainer.innerHtml = "${this.target.hp}/${this.target.maxHP}";
  }
}
