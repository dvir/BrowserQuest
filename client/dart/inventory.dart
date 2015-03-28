library inventory;

import 'dart:collection';

import 'base.dart';
import 'game.dart';
import 'inventoryitem.dart';
import 'lib/gametypes.dart';

class Inventory extends Base {

  Map<int, InventoryItem> _items = {};
  int size = 12;

  Inventory(data) {
    if (data != null) {
      this.loadFromObject(data);
    }
  }

  InventoryItem find(String id) {
    return this._items.values.firstWhere(
      (item) => item.id == id,
      orElse: () => null
    );
  }

  void throwItem(int slot) {
    InventoryItem item = this._items[slot];
    if (item != null) {
      this.remove(slot);
      Game.client.sendThrowItem(item);
    }
  }

  /**
   * The inventory slot pointed to by source can never be null as that
   * should be the swap source.
   *
   * We are optimistically doing inventory swaps on the client side.
   */
  void swap(int sourceSlot, int destinationSlot) {
    InventoryItem source = this._items[sourceSlot];

    // don't fill the items array with nulls when the destination is an empty slot
    if (this._items.containsKey(destinationSlot)) {
      this._items[sourceSlot] = this._items[destinationSlot];
    } else {
      this._items.remove(sourceSlot);
    }

    this._items[destinationSlot] = source;

    Game.client.sendInventorySwap(sourceSlot, destinationSlot);
  }

  InventoryItem get(int slot) {
    return this._items[slot];
  }

  void remove(int slot) {
    this._items.remove(slot);
  }

  void reset() {
    this._items.clear();
  }

  void update() {
    Game.updateInventory();
  }

  List<dynamic> serialize() {
    return [
      this.size,
      this._items.values.map((InventoryItem item) => item.serialize()).toList()
    ];
  }

  void forEach(void callback(int, InventoryItem)) {
    Map<int, InventoryItem> items = new SplayTreeMap.from(this._items);

    // fill empty slots with null
    for (int i = 0; i < this.size; ++i) {
      if (!items.containsKey(i)) {
        items[i] = null;
      }
    }

    items.forEach(callback);
  }

  void loadFromObject(List<dynamic> data) {
    if (data == null || data.isEmpty) {
      return;
    }

    this.size = data[0];
    this.reset();

    data[1].forEach((String id, Map<String, dynamic> item) {
      this._items[item["slot"]] = new InventoryItem(Entities.get(item['kind']), item);
    });

    this.update();
  }
}
