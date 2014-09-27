library items;

import "item.dart";
import "lib/gametypes.dart";

class Sword2 extends Weapon {

  Sword2(int id): super(id, Entities.SWORD2, "Sword", "You pick up a steel sword");
}

class Axe extends Weapon {

  Axe(int id): super(id, Entities.AXE, "Axe", "You pick up an axe");
}

class RedSword extends Weapon {

  RedSword(int id): super(id, Entities.REDSWORD, "Red Sword", "You pick up a blazing sword");
}

class BlueSword extends Weapon {

  BlueSword(int id): super(id, Entities.BLUESWORD, "Blue Sword", "You pick up a magic sword");
}

class GoldenSword extends Weapon {

  GoldenSword(int id): super(id, Entities.GOLDENSWORD, "Golden Sword", "You pick up the ultimate sword");
}

class MorningStar extends Weapon {

  MorningStar(int id): super(id, Entities.MORNINGSTAR, "Morning Star", "You pick up a morning star");
}

class LeatherArmor extends Armor {

  LeatherArmor(int id): super(id, Entities.LEATHERARMOR, "Leather Armor", "You pick up a leather armor");
}

class MailArmor extends Armor {

  MailArmor(int id): super(id, Entities.MAILARMOR, "Mail Armor", "You pick up a mail armor");
}

class PlateArmor extends Armor {

  PlateArmor(int id): super(id, Entities.PLATEARMOR, "Plate Armor", "You pick up a plate armor");
}

class RedArmor extends Armor {

  RedArmor(int id): super(id, Entities.REDARMOR, "Red Armor", "You pick up a blazing armor");
}

class GoldenArmor extends Armor {

  GoldenArmor(int id): super(id, Entities.GOLDENARMOR, "Golden Armor", "You pick up the ultimate armor");
}
