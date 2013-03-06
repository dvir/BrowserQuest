
define(['character', 'exceptions'], function(Character, Exceptions) {

    var Player = Character.extend({
        MAX_LEVEL: 10,
    
        init: function(id, name, kind) {
            this._super(id, kind);
        
            this.name = name;
        
            // Renderer
     		this.nameOffsetY = -10;
        
            // sprites
            this.spriteName = "clotharmor";
            this.weaponName = "sword1";
        
            // modes
            this.isLootMoving = false;
            this.isSwitchingWeapon = true;

            // xp
            this.level = 1;
            this.xp = 0;
            this.maxXP = 0;

            // storage
            this.storage = null;
        },
    
        loot: function(item) {
            if(item) {
                var rank, currentRank, msg, currentArmorName;
            
                if(this.currentArmorSprite) {
                    currentArmorName = this.currentArmorSprite.name;
                } else {
                    currentArmorName = this.spriteName;
                }

                if(item.type === "armor") {
                    rank = Types.getArmorRank(item.kind);
                    currentRank = Types.getArmorRank(Types.getKindFromString(currentArmorName));
                    msg = "You are wearing a better armor";
                } else if(item.type === "weapon") {
                    rank = Types.getWeaponRank(item.kind);
                    currentRank = Types.getWeaponRank(Types.getKindFromString(this.weaponName));
                    msg = "You are wielding a better weapon";
                }

                if(rank && currentRank) {
                    if(rank === currentRank) {
                        throw new Exceptions.LootException("You already have this "+item.type);
                    } else if(rank <= currentRank) {
                        throw new Exceptions.LootException(msg);
                    }
                }
            
                log.info('Player '+this.id+' has looted '+item.id);
                if(Types.isArmor(item.kind) && this.invincible) {
                    this.stopInvincibility();
                }
                item.onLoot(this);
            }
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
    
        setSpriteName: function(name) {
            this.spriteName = name;
            this.updateStorage();
        },
        
        getArmorName: function() {
            var sprite = this.getArmorSprite();
            return sprite.id;
        },
        
        getArmorSprite: function() {
            if(this.invincible) {
                return this.currentArmorSprite;
            } else {
                return this.sprite;
            }
        },
   
        getLevel: function() {
            return this.level;
        },

        setLevel: function(level) {
            this.level = level;
            this.updateStorage();
        },

        getXP: function() {
            return this.xp;
        },

        setXP: function(xp) {
            this.xp = xp;
            this.updateStorage();
        },

        setMaxXP: function(maxXP) {
            this.maxXP = maxXP;
        },

        getMaxXP: function() {
            return this.maxXP;
        },

        getName: function() {
            return this.name;
        },

        setName: function(name) {
            this.name = name;
            this.updateStorage();
        },

        getWeaponName: function() {
            return this.weaponName;
        },
    
        setWeaponName: function(name) {
            this.weaponName = name;
            this.updateStorage();
        },
    
        hasWeapon: function() {
            return this.weaponName !== null;
        },
    
        switchWeapon: function(newWeaponName) {
            var count = 14, 
                value = false, 
                self = this;
        
            var toggle = function() {
                value = !value;
                return value;
            };
        
            if(newWeaponName !== this.getWeaponName()) {
                if(this.isSwitchingWeapon) {
                    clearInterval(blanking);
                }
            
                this.switchingWeapon = true;
                var blanking = setInterval(function() {
                    if(toggle()) {
                        self.setWeaponName(newWeaponName);
                    } else {
                        self.setWeaponName(null);
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
            }
        },
    
        switchArmor: function(newArmorSprite) {
            var count = 14, 
                value = false, 
                self = this;
        
            var toggle = function() {
                value = !value;
                return value;
            };
        
            if(newArmorSprite && newArmorSprite.id !== this.getSpriteName()) {
                if(this.isSwitchingArmor) {
                    clearInterval(blanking);
                }
            
                this.isSwitchingArmor = true;
                self.setSprite(newArmorSprite);
                self.setSpriteName(newArmorSprite.id);
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
            }
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
        
            if(!this.invincible) {
                this.currentArmorSprite = this.getSprite();
                this.invincible = true;
                this.invincible_callback();      
            } else {
                // If the player already has invincibility, just reset its duration.
                if(this.invincibleTimeout) {
                    clearTimeout(this.invincibleTimeout);
                }
            }
        
            this.invincibleTimeout = setTimeout(function() {
                self.stopInvincibility();
                self.idle();
            }, 15000);
        },
    
        stopInvincibility: function() {
            this.invincible_callback();
            this.invincible = false;
        
            if(this.currentArmorSprite) {
                this.setSprite(this.currentArmorSprite);
                this.setSpriteName(this.currentArmorSprite.id);
                this.currentArmorSprite = null;
            }
            if(this.invincibleTimeout) {
                clearTimeout(this.invincibleTimeout);
            }
        },

        setStorage: function(storage) {
            this.storage = storage;
        },

        loadFromStorage: function(callback) {
            if (this.storage && this.storage.hasAlreadyPlayed()) {
                this.spriteName = this.storage.data.player.armor;
                this.weaponName = this.storage.data.player.weapon;
                this.xp = this.storage.data.player.xp;
                this.level = this.storage.data.player.level;
                this.hp = this.storage.data.player.hp;
            }

            log.debug("Loaded from storage");
            
            if (callback) {
                callback();
            }
        },

        updateStorage: function(callback) {
            if (this.storage) {
                this.storage.data.player.name = this.getName();
                this.storage.data.player.armor = this.getSpriteName();
                this.storage.data.player.weapon = this.getWeaponName();
                this.storage.data.player.xp = this.getXP();
                this.storage.data.player.level = this.getLevel();
                this.storage.data.player.hp = this.getHP();
            }
            
            log.debug("Updated storage");

            if (callback) {
                callback();
            }
        }
    });

    return Player;
});
