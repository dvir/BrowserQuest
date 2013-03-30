
define(['player', 
       'character',
       'spelleffect',
       'mob',
       'item',
       'chest',
       'entityfactory', 
       'lib/bison'], function(
           Player, 
           Character,
           SpellEffect,
           Mob,
           Item,
           Chest,
           EntityFactory, 
           BISON) {

    var GameClient = Class.extend({
        init: function(host, port) {
            this.connection = null;
            this.host = host;
            this.port = port;
    
            this.connected_callback = null;
            this.movement_callback = null;
        
            this.handlers = [];
            this.handlers[Types.Messages.WELCOME] = this.receiveWelcome;
            this.handlers[Types.Messages.MOVE] = this.receiveMove;
            this.handlers[Types.Messages.LOOTMOVE] = this.receiveLootMove;
            this.handlers[Types.Messages.ATTACK] = this.receiveAttack;
            this.handlers[Types.Messages.SPAWN] = this.receiveSpawn;
            this.handlers[Types.Messages.DESPAWN] = this.receiveDespawn;
            this.handlers[Types.Messages.SPAWN_BATCH] = this.receiveSpawnBatch;
            this.handlers[Types.Messages.HEALTH] = this.receiveHealth;
            this.handlers[Types.Messages.CHAT] = this.receiveChat;
            this.handlers[Types.Messages.EQUIP] = this.receiveEquipItem;
            this.handlers[Types.Messages.DROP] = this.receiveDrop;
            this.handlers[Types.Messages.TELEPORT] = this.receiveTeleport;
            this.handlers[Types.Messages.DAMAGE] = this.receiveDamage;
            this.handlers[Types.Messages.POPULATION] = this.receivePopulation;
            this.handlers[Types.Messages.LIST] = this.receiveList;
            this.handlers[Types.Messages.DESTROY] = this.receiveDestroy;
            this.handlers[Types.Messages.KILL] = this.receiveKill;
            this.handlers[Types.Messages.HP] = this.receiveHitPoints;
            this.handlers[Types.Messages.BLINK] = this.receiveBlink;
            this.handlers[Types.Messages.XP] = this.receiveXP;
            this.handlers[Types.Messages.LEVEL] = this.receiveLevel;
            this.handlers[Types.Messages.DATA] = this.receiveData;
            this.handlers[Types.Messages.INVENTORY] = this.receiveInventory;
            this.handlers[Types.Messages.LOOT] = this.receiveLoot;
            
            this.useBison = false;
            this.enable();
        },
    
        enable: function() {
            this.isListening = true;
        },
    
        disable: function() {
            this.isListening = false;
        },
        
        connect: function(dispatcherMode) {
            var url = "ws://"+ this.host +":"+ this.port +"/",
                self = this;
            
            log.info("Trying to connect to server : "+url);

            if(window.MozWebSocket) {
                this.connection = new MozWebSocket(url);
            } else {
                this.connection = new WebSocket(url);
            }
            
            if(dispatcherMode) {
                this.connection.onmessage = function(e) {
                    var reply = JSON.parse(e.data);

                    if(reply.status === 'OK') {
                        self.dispatched_callback(reply.host, reply.port);
                    } else if(reply.status === 'FULL') {
                        alert("BrowserQuest is currently at maximum player population. Please retry later.");
                    } else {
                        alert("Unknown error while connecting to BrowserQuest.");
                    }
                };
            } else {
                this.connection.onopen = function(e) {
                    log.info("Connected to server "+self.host+":"+self.port);
                };

                this.connection.onmessage = function(e) {
                    if(e.data === "go") {
                        if(self.connected_callback) {
                            self.connected_callback();
                        }
                        return;
                    }
                    if(e.data === 'timeout') {
                        self.isTimeout = true;
                        return;
                    }
                    
                    self.receiveMessage(e.data);
                };

                this.connection.onerror = function(e) {
                    log.error(e, true);
                };

                this.connection.onclose = function() {
                    log.debug("Connection closed");
                    $('#container').addClass('error');
                    
                    if (self.isTimeout) {
                        self.disconnected("You have been disconnected for being inactive for too long");
                    } else {
                        self.disconnected("The connection to BrowserQuest has been lost");
                    }
                };
            }
        },

        sendMessage: function(json) {
            var data;
            if(this.connection.readyState === 1) {
                if(this.useBison) {
                    data = BISON.encode(json);
                } else {
                    data = JSON.stringify(json);
                }
                this.connection.send(data);

                console.debug("dataOut: "+data);
            }
        },

        receiveMessage: function(message) {
            var data, action;
        
            if(this.isListening) {
                if(this.useBison) {
                    data = BISON.decode(message);
                } else {
                    data = JSON.parse(message);
                }

                console.debug("dataIn: " + message);

                if(data instanceof Array) {
                    if(data[0] instanceof Array) {
                        // Multiple actions received
                        this.receiveActionBatch(data);
                    } else {
                        // Only one action received
                        this.receiveAction(data);
                    }
                }
            }
        },
    
        receiveAction: function(data) {
            var action = data[0];
            if(this.handlers[action] && _.isFunction(this.handlers[action])) {
                this.handlers[action].call(this, data);
            }
            else {
                log.error("Unknown action : " + action);
            }
        },
    
        receiveActionBatch: function(actions) {
            var self = this;

            _.each(actions, function(action) {
                self.receiveAction(action);
            });
        },
    
        receiveWelcome: function(data) {
            var id = data[1],
                name = data[2],
                x = data[3],
                y = data[4],
                hp = data[5];
        
            if(this.welcome_callback) {
                this.welcome_callback(id, name, x, y, hp);
            }
        },
    
        receiveMove: function(data) {
            var id = data[1],
                x = data[2],
                y = data[3];
        
            if (id !== globalGame.player.id) {
                var entity = globalGame.getEntityById(id);
                if (entity) {
                    if (globalGame.player.isAttackedBy(entity)) {
                        globalGame.tryUnlockingAchievement("COWARD");
                    }
                    entity.disengage();
                    entity.idle();
                    globalGame.makeCharacterGoTo(entity, x, y);
                }
            }
        },
    
        receiveLootMove: function(data) {
            var id = data[1], 
                item = data[2];
        
            if(this.lootmove_callback) {
                this.lootmove_callback(id, item);
            }
        },
    
        receiveLoot: function(data) {
            var item = data[1];
        
            if(this.loot_callback) {
                this.loot_callback(item);
            }
        },
    
        receiveAttack: function(data) {
            var attacker = data[1], 
                target = data[2];
        
            if(this.attack_callback) {
                this.attack_callback(attacker, target);
            }
        },
    
        receiveSpawn: function(data) {
            var id = data[1],
                kind = data[2],
                x = data[3],
                y = data[4];
        
            if (Types.isSpell(kind)) {
                //@TODO: handle properly
                return;

                var spell = EntityFactory.createEntity(kind, id);
            
            } else if(Types.isItem(kind)) {
                var item = EntityFactory.createEntity(kind, id);
            
                log.info("Spawned " + Types.getKindAsString(item.kind) + " (" + item.id + ") at "+x+", "+y);
                globalGame.addItem(item, x, y);
            } else if(Types.isChest(kind)) {
                var chest = EntityFactory.createEntity(kind, id);

                log.info("Spawned chest (" + chest.id + ") at "+x+", "+y);
                chest.setSprite(globalGame.sprites[chest.getSpriteName()]);
                chest.setGridPosition(x, y);
                chest.setAnimation("idle_down", 150);
                globalGame.addEntity(chest, x, y);
            
                chest.onOpen(function() {
                    chest.stopBlinking();
                    chest.setSprite(globalGame.sprites["death"]);
                    chest.setAnimation("death", 120, 1, function() {
                        log.info(chest.id + " was removed");
                        globalGame.removeEntity(chest);
                        globalGame.removeFromRenderingGrid(chest, chest.gridX, chest.gridY);
                        globalGame.previousClickPosition = {};
                    });
                });
            } else {
                var name, orientation, targetId, weapon, armor, hp, maxHP;
            
                hp = data[5];
                maxHP = data[6];
                orientation = data[7];
                targetId = data[8];

                if (Types.isPlayer(kind)) {
                    name = data[9];
                    armor = data[10];
                    weapon = data[11];
                } else if(Types.isMob(kind)) {

                }

                var character = EntityFactory.createEntity(kind, id, name);
                character.hp = hp;
                character.maxHP = maxHP;
            
                if (character instanceof Player) {
                    character.equipWeapon(weapon);
                    character.equipArmor(armor);
                }
            
                if (!globalGame.entityIdExists(character.id)) {
                    try {
                        if (character.id !== globalGame.player.id) {
                            var kindString = Types.getKindAsString(character.skin);
                            character.setSprite(globalGame.sprites[kindString]);
                            character.setGridPosition(x, y);
                            character.setOrientation(orientation);
                            character.idle();

                            globalGame.addEntity(character);
                    
                            log.info("Spawned " + Types.getKindAsString(character.kind) + " (" + character.id + ") at "+character.gridX+", "+character.gridY);
                    
                            if (character instanceof Mob) {
                                if(targetId) {
                                    var player = globalGame.getEntityById(targetId);
                                    if(player) {
                                        globalGame.createAttackLink(character, player);
                                    }
                                }
                            }
                        }
                    }
                    catch(e) {
                        log.error("ReceiveSpawn failed. Error: "+e);
                        log.error(e.stack);
                    }
                } else {
                    log.debug("Character "+character.id+" already exists. Don't respawn.");
                }
            }
        },
    
        receiveDespawn: function(data) {
            var id = data[1];
        
            var entity = globalGame.getEntityById(id, true);
            if (entity) {
                entity.removed = true;

                log.info("Despawning " + Types.getKindAsString(entity.kind) + " (" + entity.id+ ")");
                
                if (entity.gridX === globalGame.previousClickPosition.x
                   && entity.gridY === globalGame.previousClickPosition.y) 
                {
                    globalGame.previousClickPosition = {};
                }
              
                if (entity instanceof SpellEffect) {
                    globalGame.removeSpellEffect(entity);
                } else if (entity instanceof Item) {
                    globalGame.removeItem(entity);
                } else if (entity instanceof Character) {
                    entity.forEachAttacker(function(attacker) {
                        if (attacker.canReachTarget()) {
                            attacker.hit();
                        }
                    });
                    entity.die();
                } else if (entity instanceof Chest) {
                    entity.open();
                }
                
                entity.clean();
            }
        },
    
        receiveHealth: function(data) {
            var entityId = data[1],
                hp = data[2],
                maxHP = data[3],
                isRegen = data[4] ? true : false;
        
            if (this.health_callback) {
                this.health_callback(entityId, hp, maxHP, isRegen);
            }
        },
    
        receiveChat: function(data) {
            var id = data[1],
                text = data[2];
        
            if(this.chat_callback) {
                this.chat_callback(id, text);
            }
        },
    
        receiveEquipItem: function(data) {
            var id = data[1],
                itemKind = data[2];
        
            if(this.equip_callback) {
                this.equip_callback(id, itemKind);
            }
        },
    
        receiveDrop: function(data) {
            var entityId = data[1],
                id = data[2],
                kind = data[3];
        
            var item = EntityFactory.createEntity(kind, id);
            item.wasDropped = true;
            item.playersInvolved = data[4];

            var pos = data[5]; 
            if (this.drop_callback) {
                this.drop_callback(item, entityId, pos);
            }
        },
    
        receiveTeleport: function(data) {
            var id = data[1],
                x = data[2],
                y = data[3];
        
            if(this.teleport_callback) {
                this.teleport_callback(id, x, y);
            }
        },
    
        receiveDamage: function(data) {
            var entityId = data[1],
                dmg = data[2],
                attackerId = data[3];
        
            if(this.dmg_callback) {
                this.dmg_callback(entityId, dmg, attackerId);
            }
        },
    
        receivePopulation: function(data) {
            var worldPlayers = data[1],
                totalPlayers = data[2];
        
            var setWorldPlayersString = function(string) {
                    $("#instance-population").find("span:nth-child(2)").text(string);
                    $("#playercount").find("span:nth-child(2)").text(string);
                },
                setTotalPlayersString = function(string) {
                    $("#world-population").find("span:nth-child(2)").text(string);
                };
            
            $("#playercount").find("span.count").text(worldPlayers);
            
            $("#instance-population").find("span").text(worldPlayers);
            if (worldPlayers == 1) {
                setWorldPlayersString("player");
            } else {
                setWorldPlayersString("players");
            }
            
            $("#world-population").find("span").text(totalPlayers);
            if(totalPlayers == 1) {
                setTotalPlayersString("player");
            } else {
                setTotalPlayersString("players");
            }
        },

        receiveKill: function(data) {
            var mobKind = data[1];
        
            if(this.kill_callback) {
                this.kill_callback(mobKind);
            }
        },
    
        receiveList: function(data) {
            data.shift();
        
            if(this.list_callback) {
                this.list_callback(data);
            }
        },
    
        receiveDestroy: function(data) {
            var id = data[1];
        
            if(this.destroy_callback) {
                this.destroy_callback(id);
            }
        },
    
        receiveHitPoints: function(data) {
            var maxHp = data[1];
        
            if(this.hp_callback) {
                this.hp_callback(maxHp);
            }
        },

        receiveXP: function(data) {
            var xp = data[1],
                maxXP = data[2],
                gainedXP = data[3];

            if (this.xp_callback) {
                this.xp_callback(xp, maxXP, gainedXP);
            }
        },
    
        receiveBlink: function(data) {
            var id = data[1];
        
            var item = globalGame.getEntityById(id);
            if (item) {
                item.blink(150);
            }
        },

        receiveLevel: function(data) {
            var level = data[1];

            if (this.level_callback) {
                this.level_callback(level);
            }
        },

        receiveData: function(data) {
            var dataObject = data[1];

            if (this.data_callback) {
                this.data_callback(dataObject);
            }
        },
        
        receiveInventory: function(data) {
            var dataObject = data[1];

            if (this.inventory_callback) {
                this.inventory_callback(dataObject);
            }
        },

        onHealth: function(callback) {
            this.health_callback = callback;
        },

        onDispatched: function(callback) {
            this.dispatched_callback = callback;
        },

        onConnected: function(callback) {
            this.connected_callback = callback;
        },
        
        disconnected: function(message) {
            if (globalGame.player) {
                globalGame.player.die();
            }
            globalGame.disconnected(message);
        },

        onWelcome: function(callback) {
            this.welcome_callback = callback;
        },

        onEntityAttack: function(callback) {
            this.attack_callback = callback;
        },
    
        onPlayerEquipItem: function(callback) {
            this.equip_callback = callback;
        },
    
        onPlayerMoveToItem: function(callback) {
            this.lootmove_callback = callback;
        },
    
        onPlayerTeleport: function(callback) {
            this.teleport_callback = callback;
        },
    
        onChatMessage: function(callback) {
            this.chat_callback = callback;
        },

        onLootItem: function(callback) {
            this.loot_callback = callback;
        },
    
        onDropItem: function(callback) {
            this.drop_callback = callback;
        },
    
        onDamage: function(callback) {
            this.dmg_callback = callback;
        },
    
        onPlayerKillMob: function(callback) {
            this.kill_callback = callback;
        },
    
        onEntityList: function(callback) {
            this.list_callback = callback;
        },
    
        onEntityDestroy: function(callback) {
            this.destroy_callback = callback;
        },
    
        onPlayerChangeXP: function(callback) {
            this.xp_callback = callback;
        },

        onPlayerChangeLevel: function(callback) {
            this.level_callback = callback;
        },

        onDataUpdate: function(callback) {
            this.data_callback = callback;
        },

        onInventoryUpdate: function(callback) {
            this.inventory_callback = callback;
        },
    
        sendInventory: function(inventory) {
            this.sendMessage([Types.Messages.INVENTORY,
                              inventory.serialize()]);
        },

        sendInventoryItem: function(inventoryItem) {
            this.sendMessage([Types.Messages.INVENTORYITEM,
                              inventoryItem.serialize()]);
        },

        sendInventorySwap: function(first, second) {
            this.sendMessage([Types.Messages.INVENTORYSWAP,
                              first,
                              second]);
        },

        sendUseItem: function(item, target) {
            var message = [Types.Messages.USEITEM,
                           item.id];
            if (target) {
                message.push(target.id);
            }

            this.sendMessage(message);
        },

        sendUseSpell: function(spell, target, orientation, trackingId) {
            var message = [Types.Messages.USESPELL,
                           spell.kind];

            var targetId = null;
            if (target) {
                targetId = target.id;
            }
            message.push(targetId);
            message.push(orientation);
            message.push(trackingId);

            this.sendMessage(message);
        },

        sendSkillbar: function(skillbar) {
            this.sendMessage([Types.Messages.SKILLBAR,
                              skillbar.serialize()]);
        },

        sendThrowItem: function(item, target) {
            var message = [Types.Messages.THROWITEM,
                           item.id];
            if (target) {
                message.push(target.id);
            }

            this.sendMessage(message);
        },

        sendHello: function(player, isResurrection) {
            this.sendMessage([Types.Messages.HELLO,
                              player.name]);
        },

        sendResurrect: function() {
            this.sendMessage([Types.Messages.RESURRECT]);
        },

        sendMove: function(x, y) {
            this.sendMessage([Types.Messages.MOVE,
                              x,
                              y]);
        },
    
        sendLootMove: function(item, x, y) {
            this.sendMessage([Types.Messages.LOOTMOVE,
                              x,
                              y,
                              item.id]);
        },
    
        sendAggro: function(mob) {
            this.sendMessage([Types.Messages.AGGRO,
                              mob.id]);
        },
    
        sendAttack: function(mob) {
            this.sendMessage([Types.Messages.ATTACK,
                              mob.id]);
        },
    
        sendHit: function(mob) {
            this.sendMessage([Types.Messages.HIT,
                              mob.id]);
        },
    
        sendHurt: function(mob) {
            this.sendMessage([Types.Messages.HURT,
                              mob.id]);
        },
    
        sendChat: function(text) {
            this.sendMessage([Types.Messages.CHAT,
                              text]);
        },
    
        sendLoot: function(item) {
            this.sendMessage([Types.Messages.LOOT,
                              item.id]);
        },
    
        sendTeleport: function(x, y) {
            this.sendMessage([Types.Messages.TELEPORT,
                              x,
                              y]);
        },
    
        sendWho: function(ids) {
            ids.unshift(Types.Messages.WHO);
            this.sendMessage(ids);
        },
    
        sendZone: function() {
            this.sendMessage([Types.Messages.ZONE]);
        },
    
        sendOpen: function(chest) {
            this.sendMessage([Types.Messages.OPEN,
                              chest.id]);
        },
    
        sendCheck: function(id) {
            this.sendMessage([Types.Messages.CHECK,
                              id]);
        }
    });
    
    return GameClient;
});
