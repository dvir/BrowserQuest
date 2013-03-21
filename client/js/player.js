
define(['character', 'exceptions', 'inventory'], function(Character, Exceptions, Inventory) {

    var Player = Character.extend({
        MAX_LEVEL: 10,
        
        data: {
            // xp
            xp: 0,
            maxXP: 0,
        },
    
        init: function(id, name, kind) {
            this._super(id, kind);

            this._xp = 0;
            this._maxXP = 0;
            this._inventory = null;

            this.name = name;
        
            // Renderer
     		this.nameOffsetY = -10;
        
            // modes
            this.isLootMoving = false;
            this.isSwitchingWeapon = true;

            // storage
            this.storage = null;
        },

        loadInventory: function(data) {
            if (this.inventory) {
                this.inventory.loadFromObject(data);
            } else {
                this.inventory = new Inventory(data);
            }
        },

        lootedArmor: function(item) {
            // make sure that we aren't weilding the same armor already,
            // and that it's better than what we already have
            if(item.kind !== this.armor && 
               Types.getArmorRank(item.kind) > Types.getArmorRank(this.armor)) 
            {
                this.switchArmor(item);
            }
        },
    
        lootedWeapon: function(item) {
            // make sure that we aren't weilding the same weapon already,
            // and that it's better than what we already have
            if(item.kind !== this.weapon && 
               Types.getWeaponRank(item.kind) > Types.getWeaponRank(this.weapon)) 
            {
                this.switchWeapon(item);
            }
        },
    
        loot: function(item) {
            log.info('Player '+this.id+' has looted '+item.id);

            // commented out. Why stop invincibiility?! 
            /*
            if(Types.isArmor(item.kind) && this.invincible) {
                this.stopInvincibility();
            }
            */

            item.onLoot(this);
        },
    
        /**
         * Returns true if the character is currently walking towards an item in order to loot it.
         */
        isMovingToLoot: function() {
            return this.isLootMoving;
        },
    
        getSpriteName: function() {
            return this.spriteName;
        },
    
        get skin() {
            if (this.isDying) {
                return Types.Entities.DEATH;
            }

            if (this.invincible) {
                return Types.Entities.FIREFOX;
            }

            if (!this.armor) {
                return this.kind;
            }

            return this.armor;
        },
   
        get xp() {
            return this._xp;
        },

        set xp(xp) {
            this._xp = xp;
        },

        get maxXP() {
            return this._maxXP;
        },

        set maxXP(maxXP) {
            this._maxXP = maxXP;
        },

        getWeaponName: function() {
            return this.weaponName;
        },
    
        setWeaponName: function(name) {
            this.weaponName = name;
        },
    
        hasWeapon: function() {
            return this.weaponName !== null;
        },
    
        switchWeapon: function(item) {
            var count = 14, 
                value = false, 
                self = this;
        
            var toggle = function() {
                value = !value;
                return value;
            };
        
            if(this.isSwitchingWeapon) {
                clearInterval(blanking);
            }
        
            this.switchingWeapon = true;
            var blanking = setInterval(function() {
                if(toggle()) {
//                        self.setWeaponName(newWeaponName);
                    self.weapon = item.kind;
                } else {
//                        self.setWeaponName(null);
                    self.weapon = null;
                }

                count -= 1;
                if(count === 1) {
                    clearInterval(blanking);
                    self.switchingWeapon = false;
                
                    if(self.switch_callback) {
                        self.switch_callback();
                    }
                }
            }, 90);
        },
    
        switchArmor: function(item) {
            var count = 14, 
                value = false, 
                self = this;
        
            var toggle = function() {
                value = !value;
                return value;
            };
        
            if(this.isSwitchingArmor) {
                clearInterval(blanking);
            }
        
            this.isSwitchingArmor = true;
            self.armor = item.kind;
            var blanking = setInterval(function() {
                self.setVisible(toggle());

                count -= 1;
                if(count === 1) {
                    clearInterval(blanking);
                    self.isSwitchingArmor = false;
                
                    if(self.switch_callback) {
                        self.switch_callback();
                    }
                }
            }, 90);
        },
    
        onArmorLoot: function(callback) {
            this.armorloot_callback = callback;
        },

        onSwitchItem: function(callback) {
            this.switch_callback = callback;
        },
        
        onInvincible: function(callback) {
            this.invincible_callback = callback;
        },

        startInvincibility: function() {
            var self = this;
        
            if (this.invincible) {
                // If the player already has invincibility, just reset its duration.
                if(this.invincibleTimeout) {
                    clearTimeout(this.invincibleTimeout);
                }
            } else {
                this.invincible = true;
                this.invincible_callback();      
            }
        
            this.invincibleTimeout = setTimeout(function() {
                self.stopInvincibility();
                self.idle();
            }, 15000);
        },
    
        stopInvincibility: function() {
            this.invincible_callback();
            this.invincible = false;
        
            if(this.invincibleTimeout) {
                clearTimeout(this.invincibleTimeout);
            }
        },

        setStorage: function(storage) {
            this.storage = storage;
        },

        loadFromStorage: function(callback) {
            return;

            if (this.storage && this.storage.hasAlreadyPlayed()) {
                this.armor = this.storage.data.player.armor;
                this.weapon = this.storage.data.player.weapon;
            }

            log.debug("Loaded from storage");
            
            if (callback) {
                callback();
            }
        },

        updateStorage: function(callback) {
            return;

            if (this.storage) {
                this.storage.data.player.name = this.name;
                this.storage.data.player.armor = this.armor;
                this.storage.data.player.weapon = this.weapon;
            }
            
            log.debug("Updated storage");

            if (callback) {
                callback();
            }
        },

        loadFromObject: function(data) {
            // x and y in server are mapped to gridX and gridY on client
            this.setGridPosition(data.x, data.y);
            delete data.x;
            delete data.y;

            // set inventory data
            this.loadInventory(data.inventory);
            delete data.inventory;

            $.extend(this, data);
        }
    });

    return Player;
});
