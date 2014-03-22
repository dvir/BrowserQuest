library inventoryitem;

import "character.dart";
import "game.dart";
import "item.dart";
import "../shared/dart/gametypes.dart";

class InventoryItem extends Item {

  int slot = 0;
  int barSlot = 0;

  InventoryItem(Entities kind, [data = null]): super(0, kind) {

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
    this.id = data.inventoryId;
    this.kind = data.kind;
    this.amount = data.amount;
    this.slot = data.slot;
    this.barSlot = data.barSlot;
  }

  Map serialize() {
    return {
      "id": this.id,
      "kind": this.kind,
      "amount": this.amount,
      "slot": this.slot,
      "barSlot": this.barSlot
    };
  }
}
