
var cls = require("./lib/class"),
    _ = require("underscore"),
    Messages = require("./message"),
    Utils = require("./utils"),
    Properties = require("./properties"),
    Formulas = require("./formulas"),
    check = require("./format").check,
    DB = require("./db"),
    Inventory = require("./inventory"),
    Types = require("../../shared/js/gametypes");

module.exports = Player = Character.extend({
    init: function(connection, worldServer) {
        var self = this;
        
        this.server = worldServer;
        this.connection = connection;

        this._super(this.connection.id, "player", Types.Entities.WARRIOR, 0, 0, "");

        Utils.Mixin(this.data, {
            xp: 0
        });

        this.inventory = null; 

        this.hasEnteredGame = false;
        this.isDead = false;
        this.isAutoEquip = true;
        this.haters = {};
        this.lastCheckpoint = null;
        this.formatChecker = new FormatChecker();
        this.disconnectTimeout = null;
        
        this.connection.listen(function(message) {
            var action = parseInt(message[0]);
            
            log.debug("Received: "+message);
            if(!check(message)) {
                self.connection.close("Invalid "+Types.getMessageTypeAsString(action)+" message format: "+message);
                return;
            }
            
            if(!self.hasEnteredGame && action !== Types.Messages.HELLO) { // HELLO must be the first message
                self.connection.close("Invalid handshake message: "+message);
                return;
            }
            if(self.hasEnteredGame && !self.isDead && action === Types.Messages.HELLO) { // HELLO can be sent only once
                self.connection.close("Cannot initiate handshake twice: "+message);
                return;
            }
            
            self.resetTimeout();
            
            if(action === Types.Messages.HELLO) {
                var name = Utils.sanitize(message[1]);
                
                // If name was cleared by the sanitizer, give a default name.
                // Always ensure that the name is not longer than a maximum length.
                // (also enforced by the maxlength attribute of the name input element).
                self.name = (name === "") ? "lorem ipsum" : name.substr(0, 15);

                self.kind = Types.Entities.WARRIOR;
                self.orientation = Utils.randomOrientation();
                
                // find previous player with this id
                Players.findOne({name: self.name}, function(err, dbPlayer){
                    if (dbPlayer) {
                        log.debug("Found previous player record '"+dbPlayer.name+"'");
                    } else {
                        log.debug("Creating new player record '"+self.name+"'");
                        var dbPlayer = new Players({
                            name: self.name, 
                            xp: self.xp, 
                            level: self.level, 
                            hp: self.hp,
                            armor: 21,
                            weapon: 60,
                            x: self.x,
                            y: self.y
                        });
                        dbPlayer.save();
                    }

                    self.setDBEntity(dbPlayer, function(){
                        self.updatePosition();
                        self.send([Types.Messages.WELCOME, self.getData()]);
                        self.hasEnteredGame = true;
                        self.isDead = false;

                        self.server.addPlayer(self, function(){
                            self.server.enter_callback(self);
                        });
                    });
                });
            }
            else if(action === Types.Messages.WHO) {
                message.shift();
                self.server.pushSpawnsToPlayer(self, message);
            }
            else if(action === Types.Messages.ZONE) {
                self.zone_callback();
            }
            else if(action === Types.Messages.CHAT) {
                var msg = Utils.sanitize(message[1]);
                
                // Sanitized messages may become empty. No need to broadcast empty chat messages.
                if(msg && msg !== "") {
                    msg = msg.substr(0, 60); // Enforce maxlength of chat input
                    self.broadcastToZone(new Messages.Chat(self, msg), false);
                }
            }
            else if(action === Types.Messages.MOVE) {
                if(self.move_callback) {
                    var x = message[1],
                        y = message[2];
                    
                    if(self.server.isValidPosition(x, y)) {
                        self.setPosition(x, y);
                        self.clearTarget();
                        
                        self.broadcast(new Messages.Move(self));
                        self.move_callback(self.x, self.y);
                    }
                }
            }
            else if(action === Types.Messages.LOOTMOVE) {
                if(self.lootmove_callback) {
                    self.setPosition(message[1], message[2]);
                    
                    var item = self.server.getEntityById(message[3]);
                    if(item) {
                        self.clearTarget();

                        self.broadcast(new Messages.LootMove(self, item));
                        self.lootmove_callback(self.x, self.y);
                    }
                }
            }
            else if(action === Types.Messages.AGGRO) {
                if(self.move_callback) {
                    self.server.handleMobHate(message[1], self.id, 5);
                }
            }
            else if(action === Types.Messages.ATTACK) {
                var mob = self.server.getEntityById(message[1]);
                
                if(mob) {
                    self.setTarget(mob);
                    self.server.broadcastAttacker(self);
                }
            }
            else if(action === Types.Messages.HIT) {
                var mob = self.server.getEntityById(message[1]);
                if(mob) {
                    var dmg = Formulas.dmg(self.weaponLevel, mob.armorLevel);
                    
                    if (dmg > 0) {
                        mob.receiveDamage(dmg, self.id);
                        self.server.handleMobHate(mob.id, self.id, dmg);
                        self.server.handleHurtEntity(mob, self, dmg);
                    }
                }
            }
            else if(action === Types.Messages.HURT) {
                var mob = self.server.getEntityById(message[1]);
                if(mob && self.hp > 0) {
                    var damage = Formulas.dmg(mob.weaponLevel, self.armorLevel);
                    self.hp -= damage;
                    self.server.handleHurtEntity(self, mob, damage);
                    
                    if(self.hp <= 0) {
                        self.isDead = true;
                        if(self.firepotionTimeout) {
                            clearTimeout(self.firepotionTimeout);
                        }
                    }
                }
            }
            else if(action === Types.Messages.LOOT) {
                var item = self.server.getEntityById(message[1]);
                if (item) {
                    if(Types.isItem(item.kind)) {
                        self.lootedItem(item);
                    }
                }
            }
            else if(action === Types.Messages.TELEPORT) {
                var x = message[1],
                    y = message[2];
                if(self.server.isValidPosition(x, y)) {
                    self.setPosition(x, y);
                    self.clearTarget();
                    
                    self.broadcast(new Messages.Teleport(self));
                    self.send(new Messages.Teleport(self).serialize());
                    
                    self.server.handlePlayerVanish(self);
                    self.server.pushRelevantEntityListTo(self);
                }
            }
            else if(action === Types.Messages.OPEN) {
                var chest = self.server.getEntityById(message[1]);
                if(chest && chest instanceof Chest) {
                    self.server.handleOpenedChest(chest, self);
                }
            }
            else if(action === Types.Messages.CHECK) {
                var checkpoint = self.server.map.getCheckpoint(message[1]);
                if(checkpoint) {
                    self.lastCheckpoint = checkpoint;
                }
            }
            else {
                if(self.message_callback) {
                    self.message_callback(message);
                }
            }
        });
        
        this.connection.onClose(function() {
            if(self.firepotionTimeout) {
                clearTimeout(self.firepotionTimeout);
            }
            clearTimeout(self.disconnectTimeout);
            if(self.exit_callback) {
                self.exit_callback();
            }
        });
        
        this.connection.sendUTF8("go"); // Notify client that the HELLO/WELCOME handshake can start
    },
    
    destroy: function() {
        var self = this;
        
        this.forEachAttacker(function(mob) {
            mob.clearTarget();
        });
        this.attackers = {};
        
        this.forEachHater(function(mob) {
            mob.forgetPlayer(self.id);
        });
        this.haters = {};
    },
    
    getState: function() {
        var basestate = this._getBaseState(),
            state = [this.name, this.orientation, this.armor, this.weapon];

        if(this.target) {
            state.push(this.target);
        }
        
        return basestate.concat(state);
    },
    
    send: function(message) {
        this.connection.send(message);
    },
    
    broadcast: function(message, ignoreSelf) {
        if(this.broadcast_callback) {
            this.broadcast_callback(message, ignoreSelf === undefined ? true : ignoreSelf);
        }
    },
    
    broadcastToZone: function(message, ignoreSelf) {
        if(this.broadcastzone_callback) {
            this.broadcastzone_callback(message, ignoreSelf === undefined ? true : ignoreSelf);
        }
    },
    
    onExit: function(callback) {
        this.exit_callback = callback;
    },
    
    onMove: function(callback) {
        this.move_callback = callback;
    },
    
    onLootMove: function(callback) {
        this.lootmove_callback = callback;
    },
    
    onZone: function(callback) {
        this.zone_callback = callback;
    },
    
    onOrient: function(callback) {
        this.orient_callback = callback;
    },
    
    onMessage: function(callback) {
        this.message_callback = callback;
    },
    
    onBroadcast: function(callback) {
        this.broadcast_callback = callback;
    },
    
    onBroadcastToZone: function(callback) {
        this.broadcastzone_callback = callback;
    },
    
    equip: function(item) {
        return new Messages.EquipItem(this, item);
    },
    
    addHater: function(mob) {
        if(mob) {
            if(!(mob.id in this.haters)) {
                this.haters[mob.id] = mob;
            }
        }
    },
    
    removeHater: function(mob) {
        if(mob && mob.id in this.haters) {
            delete this.haters[mob.id];
        }
    },
    
    forEachHater: function(callback) {
        _.each(this.haters, function(mob) {
            callback(mob);
        });
    },

    useItem: function(item) {
        var self = this;

        if (item.kind === Types.Entities.FIREPOTION) {
            self.broadcast(self.equip(Types.Entities.FIREFOX));
            self.firepotionTimeout = setTimeout(function() {
                self.broadcast(self.equip(self.armor)); // return to normal after 15 sec
                self.firepotionTimeout = null;
            }, 15000);
        } else if (Types.isHealingItem(item.kind)) {
            var amount;
            
            switch (kind) {
                case Types.Entities.FLASK: 
                    amount = 40;
                    break;
                case Types.Entities.BURGER: 
                    amount = 100;
                    break;
            }
            
            if (!self.hasFullHealth()) {
                self.regenHealthBy(amount);
                self.broadcast(self.health());
            }
        }

        self.broadcast(item.despawn());
        self.server.removeEntity(item);
    },
  
    lootedItem: function(item) {
        var self = this;

        if (item.useOnPickup) {
            self.useItem(item);
            return;
        }

        if (this.inventory.add(item)) {
            log.debug(this.name + " looted " + Types.getKindAsString(item.kind));
            self.server.pushToPlayer(self, self.loot(item));
            self.broadcast(item.despawn());
            self.server.removeEntity(item);
            if (this.isAutoEquip) {
                if ((Types.isArmor(item.kind) && Types.getArmorRank(item.kind) > Types.getArmorRank(this.armor)) ||
                    (Types.isWeapon(item.kind) && Types.getWeaponRank(item.kind) > Types.getWeaponRank(this.weapon)))
                {
                    this.equipItem(item);
                    this.inventory.remove(item);
                    return;
                }
            }

            this.send(new Messages.Inventory(this.inventory).serialize());
        } else {
            // no room for this item in the inventory!
            // do not pick it up.
            return;
        }
    },

    equipItem: function(item) {
        log.debug(this.name + " equips " + Types.getKindAsString(item.kind));
        
        if(Types.isArmor(item.kind)) {
            this.armor = item.kind;
        } else if(Types.isWeapon(item.kind)) {
            this.weapon = item.kind;
        }

        this.broadcast(this.equip(item.kind));
    },
  
    killed: function(victim) {
        this.send(new Messages.Kill(victim).serialize());

        var xp = Formulas.xp(this, victim);
        this.xp += xp;
    },
    
    loot: function(item) {
        return new Messages.Loot(item);
    },

    getId: function() {
        return this.dbEntity._id;
    },

    set xp(xp) {
        var diff = xp - this.xp;

        if (xp > this.maxXP) {
            // level up!
            this.data.xp = xp - this.maxXP;
            this.levelUp();
        } else {
            this.data.xp = xp;
        }
       
        this.send(new Messages.XP(this.xp, this.maxXP, diff).serialize());
    },

    get xp() {
        return this.data.xp;
    },

    get maxXP() {
        return this.level*100;
    },

    levelUp: function() {
        this.level++;
        this.hp = this.maxHP;

        this.send(new Messages.Data(this.getData()).serialize());
    },

    updatePosition: function() {
        if(this.requestpos_callback) {
            var pos = this.requestpos_callback();
            this.setPosition(pos.x, pos.y);
        }
    },
    
    onRequestPosition: function(callback) {
        this.requestpos_callback = callback;
    },
    
    resetTimeout: function() {
        clearTimeout(this.disconnectTimeout);
        this.disconnectTimeout = setTimeout(this.timeout.bind(this), 1000 * 60 * 15); // 15 min.
    },
    
    timeout: function() {
        this.connection.sendUTF8("timeout");
        this.connection.close("Player was idle for too long");
    },

    setDBEntity: function(dbEntity, callback) {
        this.dbEntity = dbEntity;

        this.loadFromDB(callback);
    },

    loadFromDB: function(callback) {
        if (!this.dbEntity) return;
        
        this._super();
        
        Utils.Mixin(this.data, {
            name: this.dbEntity.name,
            level: this.dbEntity.level,
            hp: this.dbEntity.hp,
            xp: this.dbEntity.xp,
            weapon: this.dbEntity.weapon,
            armor: this.dbEntity.armor,
            x: this.dbEntity.x,
            y: this.dbEntity.y
        });

        this.inventory = new Inventory(this, callback);
    },

    save: function() {
        if (!this.dbEntity) return;

//        Utils.Mixin(this.dbEntity, this.data);
        this.dbEntity.xp = this.data.xp;
        this.dbEntity.hp = this.data.hp;
        this.dbEntity.level = this.data.level;
        this.dbEntity.name = this.data.name;
        this.dbEntity.weapon = this.data.weapon;
        this.dbEntity.armor = this.data.armor;
        this.dbEntity.x = this.data.x;
        this.dbEntity.y = this.data.y;

        this._super();
        this.inventory.save();
    },
    
    getData: function() {
        var dataObject = this.data;
        Utils.Mixin(dataObject, {
            maxXP: this.maxXP,
            maxHP: this.maxHP,
            id: this.id,
            inventory: this.inventory.serialize() 
        });

        return dataObject;
    }
});
