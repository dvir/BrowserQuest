
define(['inventoryitem'], function(InventoryItem){
    var InventoryItemFactory = {
        get: function(itemId) { 
            for (var i in globalInventoryItems) {
                var curItem = globalInventoryItems[i];
                if (curItem && curItem.id == itemId) {
                   return curItem; 
                }
            }

            return null;
        },

        remove: function(itemId) {
            for (var i in globalInventoryItems) {
                var curItem = globalInventoryItems[i];
                if (curItem && curItem.id == itemId) {
                    delete globalInventoryItems[i];
                    return true;
                }
            }

            return false;
        },

        getCreate: function(itemId, item) {
            var curItem = this.get(itemId);
            if (curItem) {
               curItem.loadFromObject(item);
               return curItem;
            }
            return new InventoryItem(item.kind, item);
        }
    };

    return InventoryItemFactory;
});
