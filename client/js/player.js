
define(['character', 
        'exceptions', 
        'inventory', 
        'skillbar',
        'chest',
        'npc'], function(
        Character, 
        Exceptions, 
        Inventory, 
        Skillbar, 
        Chest,
        Npc) {

    var Player = Character.extend({
        data: {
            // xp
            xp: 0,
            maxXP: 0,
        },
    
        init: function(id, name, kind) {
            this._super(id, kind);

            this._xp = 0;
            this._maxXP = 0;

            this.name = name;
        
            // Renderer
     		this.nameOffsetY = -10;
        
            // modes
            this.isLootMoving = false;
            this.isSwitchingWeapon = true;

            // storage
            this.storage = null;
            
            this.inventory = new Inventory();
            this.skillbar = new Skillbar();
        },

        beforeStep: function() {
            var blockingEntity = globalGame.getEntityAt(this.nextGridX, this.nextGridY);
            if (blockingEntity && blockingEntity.id !== this.id) {
                log.debug("Blocked by " + blockingEntity.id);
            }

            globalGame.unregisterEntityPosition(this);
        },

        step: function() {
            if (this.hasNextStep()) {
                globalGame.registerEntityDualPosition(this);
            }
        
            if (globalGame.isZoningTile(this.gridX, this.gridY)) {
                globalGame.enqueueZoningFrom(this.gridX, this.gridY);
            }
       
            var self = this;
            this.forEachAttacker(function(attacker) {
                if(attacker.isAdjacent(attacker.target)) {
                    attacker.lookAtTarget();
                } else {
                    attacker.follow(self);
                }
            });
        
            if((this.gridX <= 85 && this.gridY <= 179 && this.gridY > 178) || (this.gridX <= 85 && this.gridY <= 266 && this.gridY > 265)) {
                globalGame.tryUnlockingAchievement("INTO_THE_WILD");
            }
            
            if(this.gridX <= 85 && this.gridY <= 293 && this.gridY > 292) {
                globalGame.tryUnlockingAchievement("AT_WORLDS_END");
            }
            
            if(this.gridX <= 85 && this.gridY <= 100 && this.gridY > 99) {
                globalGame.tryUnlockingAchievement("NO_MANS_LAND");
            }
            
            if(this.gridX <= 85 && this.gridY <= 51 && this.gridY > 50) {
                globalGame.tryUnlockingAchievement("HOT_SPOT");
            }
            
            if(this.gridX <= 27 && this.gridY <= 123 && this.gridY > 112) {
                globalGame.tryUnlockingAchievement("TOMB_RAIDER");
            }
        
            globalGame.updatePlayerCheckpoint();
        
            if(!this.isDead) {
                globalGame.audioManager.updateMusic();
            }
        },

        requestPathfindingTo: function(x, y) {
            var ignored = [this]; // Always ignore self
        
            if (this.hasTarget()) {
                ignored.push(this.target);
            }
            return globalGame.findPath(this, x, y, ignored);
        },

        startPathing: function(path) {
            var i = path.length - 1,
                x = path[i][0],
                y = path[i][1];
        
            if (this.isMovingToLoot()) {
                this.isLootMoving = false;
            }
            else if (!this.isAttacking()) {
                globalGame.client.sendMove(x, y);
            }
        
            // Target cursor position
            globalGame.selectedX = x;
            globalGame.selectedY = y;

            if(globalGame.renderer.mobile || globalGame.renderer.tablet) {
                globalGame.drawTarget = true;
                globalGame.clearTarget = true;
                globalGame.renderer.targetRect = globalGame.renderer.getTargetBoundingRect();
                globalGame.checkOtherDirtyRects(globalGame.renderer.targetRect, null, globalGame.selectedX, globalGame.selectedY);
            }
        },
        stopPathing: function(x, y) {
            globalGame.selectedCellVisible = false;
        
            if(globalGame.isItemAt(x, y)) {
                var item = globalGame.getItemAt(x, y);
            
                // notify the server that the user is trying
                // to loot the item
                globalGame.client.sendLoot(item); 
            }
        
            if(!this.hasTarget() && globalGame.map.isDoor(x, y)) {
                var dest = globalGame.map.getDoorDestination(x, y);
                globalGame.teleport(dest);
            }
        
            if(this.target instanceof Npc) {
                globalGame.makeNpcTalk(this.target);
            } else if(this.target instanceof Chest) {
                globalGame.client.sendOpen(this.target);
                globalGame.audioManager.playSound("chest");
            }
        
            var self = this;
            this.forEachAttacker(function(attacker) {
                if(!attacker.isAdjacentNonDiagonal(self)) {
                    attacker.follow(self);
                }
            });
        
            globalGame.unregisterEntityPosition(this);
            globalGame.registerEntityPosition(this);
        },

        get areaName() {
            if (globalGame.audioManager.getSurroundingMusic(this)) {
                return globalGame.audioManager.getSurroundingMusic(this).name;
            }
        },

        loadInventory: function(data) {
            if (this.inventory) {
                this.inventory.loadFromObject(data);
            } else {
                this.inventory = new Inventory(data);
            }
        },

        loadSkillbar: function(data) {
            if (this.skillbar) {
                this.skillbar.loadFromObject(data);
            } else {
                this.skillbar = new Skillbar(data);
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

        equip: function(itemKind) {
            if(Types.isArmor(itemKind)) {
                this.equipArmor(itemKind);
            } else if(Types.isWeapon(itemKind)) {
                this.equipWeapon(itemKind);
            }
            globalGame.app.initEquipmentIcons();
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

            // set skillbar data
            this.loadSkillbar(data.skillbar);
            delete data.skillbar;

            $.extend(this, data);        
        }
    });

    return Player;
});
