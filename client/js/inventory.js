
define(['exceptions', 'inventoryitem'], function(Exceptions, InventoryItem) {
    var Inventory = Class.extend({ 
        init: function(data) {
            var self = this;

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

        add: function(item) {
        
        },

        remove: function(item) {

        },

        find: function(itemId) {
            for (var i in this._items) {
                var item = this._items[i];
                if (item && item.id == itemId) {
                    return item;
                }
            }

            return null;
        },

        swap: function(first, second) {
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

        toArray: function() {
            return this._items;
        },

        loadFromObject: function(data) {
            if ($.isEmptyObject(data)) {
                return;
            }

            var self = this;

            self._size = data[0];
            self._items = [];
            for (var i = 0; i < self.size; i++) {
                self._items[i] = null;
            }

            var ids = {};
            $.each(data[1], function(id, item) {
                if (item) {
                    self._items[item.slot] = self.inventoryItem(item.kind, item);
                    ids[item.id] = true;
                }
            });

            for (var id in globalInventoryItems) {
                if (!(id in ids)) {
                    var inventoryItem = globalInventoryItems[id];
                    inventoryItem.isDeleted = true;
                    delete globalInventoryItems[id];
                }
            }

            this.update();
        },

        serialize: function() {
            var items = []; 
            for (var i in this.items) {
                if (!this.items[i]) {
                    continue;
                }

                items[i] = this.items[i].getData();
            }

            return [this.size, items];
        },

        inventoryItem: function(kind, item) {
            for (var i in globalInventoryItems) {
                var curItem = globalInventoryItems[i];
                if (curItem && curItem.id == item.id) {
                   curItem.loadFromObject(item);
                   return curItem; 
                }
            }

            return new InventoryItem(kind, item);
        },

        update: function() {
            globalGame.updateInventory();
        },
    });

    return Inventory;
});
