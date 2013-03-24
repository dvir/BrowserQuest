
define(['item'], function(Item){
    var InventoryItem = Item.extend({
        init: function(kind, data) {
            this._super(0, kind);

            var self = this;

            if (data) {
                self.loadFromObject(data);
                globalInventoryItems[data.id] = self;
            }
        },
        
        use: function(target) {
            globalGame.client.sendUseItem(this);

            console.log("Used %s", this.itemKind);
            if (target) {
                console.log(" on %s", target.name);
            }
        },
        
        loadFromObject: function(data) {
            $.extend(this, data);
        },

        getData: function() {
            return {
                id: this.id,
                kind: this.kind,
                amount: this.amount,
                slot: this.slot,
                barSlot: this.barSlot
            };
        },

        serialize: function() {
            return this.getData();
        }
    });

    return InventoryItem;
});
