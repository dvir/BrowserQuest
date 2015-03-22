library spell;

import "dart:html";
import "dart:math";

import "base.dart";
import "character.dart";
import "game.dart";
import "spelleffect.dart";
import "lib/gametypes.dart";

class Spell extends Base {

  int id = 0;
  EntityKind kind;
  Character target;
  int cooldown = 1;
  int castTime = 1;
  String name = "N/A";
  String tooltip = "N/A";
  String spellType = "single";
  String type = "spell";

  Spell(EntityKind this.kind, Character this.target);

  SpellEffect getEffect() => new SpellEffect(null, this.kind);

  String get spellKind => Types.getKindAsString(this.kind);

  String getSpriteName() => "icon-spell-${this.spellKind}";

  void use([Character target = null]) {
    this.target = target;
    Orientation orientation = Game.player.orientation;
    int trackingId = null;

    if (this.spellType == "single") {
      // maybe apply sparks to the target?
    } else if (this.spellType == "directional") {
      SpellEffect effect = this.getEffect();
      trackingId = effect.id;
      effect.travel(Game.player);
    } else if (this.spellType == "aoe") {
      // get a big rounded(squared?) item to show
    }

    Game.client.sendUseSpell(this, target, orientation, trackingId);

    window.console.log("Used ${this.spellKind}");
    if (target != null) {
      window.console.log("on ${target.name}");
    }
  }

  void draw(context, int tilesize, int scale) {
    int radius = 90;
    int dx = this.target.x * scale;
    int dy = this.target.y * scale;
    context.save();
    context.globalAlpha = 0.3;
    context.translate(dx, dy);
    context.beginPath();
    context.arc(tilesize, tilesize, radius, 0, 2 * PI, false);
    context.fillStyle = 'rgba(0,0,200,0.5)';
    context.fill();
    context.lineWidth = 2;
    context.strokeStyle = 'rgba(0,0,0,0.5)';
    context.stroke();
    context.restore();
  }
}
