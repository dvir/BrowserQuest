define(['exceptions', 'inventoryitem', 'inventoryitemfactory'], function (Exceptions, InventoryItem, InventoryItemFactory) {

  var Inventory = Class.extend({
    init: function (data) {
      this._size = 12;
      this._items = [];

      if (data) {
        this.loadFromObject(data);
      }
    },

    get id() {
      return this._id;
    },

    get size() {
      return this._size;
    },

    add: function (item) {

    },

    remove: function (idx) {
      if (this._items[idx]) {
        InventoryItemFactory.remove(this._items[idx].id);
        this._items[idx] = null;
      }
    },

    throwItem: function (idx) {
      var item = this._items[idx];
      if (item) {
        this.remove(idx);
        globalGame.client.sendThrowItem(item);
      }
    },

    find: function (itemId) {
      for (var i in this._items) {
        var item = this._items[i];
        if (item && item.id == itemId) {
          return item;
        }
      }

      return null;
    },

    swap: function (first, second) {
      var temp = this._items[first];
      this._items[first] = this._items[second];
      this._items[second] = temp;

      if (this._items[first]) {
        this._items[first].slot = first;
      }
      if (this._items[second]) {
        this._items[second].slot = second;
      }

      globalGame.client.sendInventorySwap(first, second);
    },

    toArray: function () {
      return this._items;
    },

    loadFromObject: function (data) {
      if ($.isEmptyObject(data)) {
        return;
      }

      this._size = data[0];
      this.reset();

      var ids = {};
      $.each(data[1], function (id, item) {
        if (item) {
          this._items[item.slot] = InventoryItemFactory.getCreate(item.id, item);
          ids[item.id] = true;
        }
      }.bind(this));

      for (var id in globalInventoryItems) {
        if (!(id in ids)) {
          var inventoryItem = globalInventoryItems[id];
          inventoryItem.isDeleted = true;
          delete globalInventoryItems[id];
        }
      }

      this.update();
    },

    reset: function () {
      this._items = [];
      for (var i = 0; i < this.size; i++) {
        this._items[i] = null;
      }
    },

    serialize: function () {
      var items = [];
      for (var i in this.items) {
        if (!this.items[i]) {
          continue;
        }

        items[i] = this.items[i].getData();
      }

      return [this.size, items];
    },

    update: function () {
      globalGame.updateInventory();
    },
  });

  return Inventory;
});
