library inventoryitem;

import "character.dart";
import "game.dart";
import "item.dart";
import "lib/gametypes.dart";
import 'hero.dart';

class InventoryItem extends Item {

  int slot = 0;
  int barSlot = 0;

  // the inventory ID in which the item is in (there may be multiple
  // inventories per player, or multiple players per inventory)
  String inventoryID;

  // item ID on the server
  String itemID;

  InventoryItem(EntityKind kind, [data = null]): super(0, kind) {

    if (data != null) {
      this.load(data);
    }
  }

  void use([Character target = null]) {
    Game.client.sendUseItem(this);

    this.log_debug("Used ${this.kind}"); 
    if (target != null) {
      this.log_debug(" on ${target.name}");
    }
  }

  void load(data) {
    this.itemID = data['id'];
    this.inventoryID = data['inventoryId'];
    this.amount = data['amount'];
    this.slot = data['slot'];
    this.barSlot = data['barSlot'];
  }

  Map<String, dynamic> serialize() {
    return {
      "id": this.itemID,
      "kind": this.kind,
      "amount": this.amount,
      "slot": this.slot,
      "barSlot": this.barSlot
    };
  }
  
  void looted(Hero hero) {}
}
