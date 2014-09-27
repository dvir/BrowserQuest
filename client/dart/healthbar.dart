library healthbar;
import 'base.dart';
import 'dart:html';
import 'character.dart';
import 'player.dart';

class Healthbar extends Base {

  Element $element;
  Element $bar;
  Element $hp;
  Character character;
  int scale;
  int healthMaxWidth;

  Healthbar(Element this.$element, Character this.character, int this.scale) {
    this.$bar = this.$element.querySelector(".healthbar");
    this.$hp = this.$element.querySelector(".hitpoints");
    this.healthMaxWidth = int.parse(this.$bar.style.width) - (12 * scale);

    this.update();
  }

  void update() {
    if (this.character.hp <= 0 && !(this.character is Player)) {
      this.$element.style.display = 'none';
    } else {
      this.$element.style.display = 'block';
    }

    int barWidth = ((this.healthMaxWidth / this.character.maxHP) * (this.character.hp > 0 ? this.character.hp : 0)).round();
    this.$hp.style.width = "${barWidth}px";
    this.$bar.innerHtml = "${this.character.hp}/${this.character.maxHP}";
  }
}