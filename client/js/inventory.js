
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

        get id () {
            return this._id;
        },

        get size () {
            return this._size;
        },

        add: function(item) {
        
        },

        remove: function(item) {

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
            $.each(data[1], function(id, item) {
                self._items[id] = new InventoryItem(item.kind, item);
            });
        }
    });

    return Inventory;
});
