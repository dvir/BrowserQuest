
define(['item'], function(Item){
    var InventoryItem = Item.extend({
        init: function(kind, data) {
            this._super(0, kind);

            if (data) {
                this.loadFromObject(data);
            }
        },

        loadFromObject: function(data) {
            $.extend(this, data);
        }
    });

    return InventoryItem;
});
