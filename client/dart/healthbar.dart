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

  Healthbar(Element this.element, Character this.character) {
    this.barContainer = this.element.querySelector(".healthbar");
    this.hpContainer = this.element.querySelector(".hitpoints");

    this.update();
  }

  void update() {
    this.element.style.display = (this.character.hp == 0 && !(this.character is Player)) ? 'none' : 'block';
    int barWidth = this.character.maxHP > 0 ? (this.character.hp * 100 / this.character.maxHP).round() : 0;
    this.hpContainer.style.width = "${barWidth}%";
    this.barContainer.innerHtml = "${this.character.hp}/${this.character.maxHP}";
  }
}
