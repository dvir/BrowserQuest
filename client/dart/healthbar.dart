library healthbar;

import 'dart:html' hide Player;

import 'base.dart';
import 'character.dart';
import 'player.dart';

class Healthbar extends Base {

  Element element;
  Element barContainer;
  Element hpContainer;
  Character character;
  int scale;
  int healthMaxWidth;

  Healthbar(Element this.element, Character this.character, int this.scale) {
    this.barContainer = this.element.querySelector(".healthbar");
    this.hpContainer = this.element.querySelector(".hitpoints");
    this.healthMaxWidth = (this.barContainer.style.width.isEmpty ? 0 : int.parse(this.barContainer.style.width)) - (12 * scale);

    this.update();
  }

  void update() {
    if (this.character.hp <= 0 && !(this.character is Player)) {
      this.element.style.display = 'none';
    } else {
      this.element.style.display = 'block';
    }

    int barWidth = 0;
    if (this.character.maxHP > 0) {
      barWidth = ((this.healthMaxWidth / this.character.maxHP) * (this.character.hp > 0 ? this.character.hp : 0)).round();
    }
    this.hpContainer.style.width = "${barWidth}px";
    this.barContainer.innerHtml = "${this.character.hp}/${this.character.maxHP}";
  }
}
