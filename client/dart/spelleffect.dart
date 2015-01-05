library spelleffect;

import "dart:async";

import "character.dart";
import "entity.dart";
import "game.dart";
import "lib/gametypes.dart";

class SpellEffect extends Entity {

  bool interactable = false;
  Timer travelingTimer;
  
  SpellEffect(int id, EntityKind kind): super(id, kind);

  String get name => "";

  String get spellEffectKind => Types.getKindAsString(this.kind);

  String getSpriteName() => "spell-${this.spellEffectKind}";

  void travel(Character source) {
    Orientation orientation = source.orientation;

    Game.addSpellEffect(this, source.gridPosition);
    this.travelingTimer = new Timer.periodic(new Duration(milliseconds: 80), (Timer timer) {
      this.moveSteps(1, orientation);
    });

    new Timer(new Duration(seconds: 3), () {
      this.travelingTimer.cancel();
      Game.removeSpellEffect(this);
    });
  }
}
