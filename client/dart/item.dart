library item;

import "entity.dart";
import "hero.dart";
import "../shared/dart/gametypes.dart";

abstract class Item extends Entity {

  bool wasDropped = false;
  int amount = 1;
  int cooldown = 1;
  int castTime = 1;
  String tooltip = "N/A";
  String lootMessage;
  List<int> playersInvolved = [];

  Item(
    int id, 
    Entities kind, 
    [String name, 
    String this.lootMessage]
  ): super(id, kind) {
    this.name = name;
    this.nameOffsetY += 5;
  }

  String get itemKind => Types.getKindAsString(this.kind);

  String get type => Types.getType(this.kind);

  bool get isStackable => Types.isStackable(this.kind);

  bool hasShadow() => true;

  String getSpriteName() => "item-${this.itemKind}";
  
  void looted(Hero hero);
}

class Weapon extends Item {

  Weapon(int id, Entities kind, String name, String lootMessage): super(id, kind, name, lootMessage);

  void looted(Hero hero) {
    hero.lootedWeapon(this);
  }
}

class Armor extends Item {

  Armor(int id, Entities kind, String name, String lootMessage): super(id, kind, name, lootMessage);

  void looted(Hero hero) {
    hero.lootedArmor(this);
  }
}
