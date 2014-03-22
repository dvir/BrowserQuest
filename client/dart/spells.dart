library spells;

import "character.dart";
import "spell.dart";
import "../shared/dart/gametypes.dart";

class Frostnova extends Spell {

  String spellType = "aoe";

  Frostnova(Character target): super(Entities.FROSTNOVA, target);
}

class Frostbolt extends Spell {

  String spellType = "single";

  Frostbolt(Character target): super(Entities.FROSTBOLT, target);
}

class Fireball extends Spell {

  String spellType = "aoe";

  Fireball(Character target): super(Entities.FIREBALL, target);
}

class IceBarrier extends Spell {

  String spellType = "single";

  IceBarrier(Character target): super(Entities.ICEBARRIER, target);
}

class Polymorph extends Spell {

  String spellType = "single";

  Polymorph(Character target): super(Entities.POLYMORPH, target);
}

class Blink extends Spell {

  String spellType = "directional";

  Blink(Character target): super(Entities.BLINK, target);
}
