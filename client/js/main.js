
define(['jquery', 'app'], function($, App) {
    var app, game;

    var initApp = function() {
        $(document).ready(function() {
        	app = new App();
            app.center();
        
            if(Detect.isWindows()) {
                // Workaround for graphical glitches on text
                $('body').addClass('windows');
            }
            
            if(Detect.isOpera()) {
                // Fix for no pointer events
                $('body').addClass('opera');
            }
        
            $('body').click(function(event) {
                if($('#parchment').hasClass('credits')) {
                    app.toggleCredits();
                }
                
                if($('#parchment').hasClass('about')) {
                    app.toggleAbout();
                }
            });
	
        	$('.barbutton').click(function() {
        	    $(this).toggleClass('active');
        	});
	
        	$('#chatbutton').click(function() {
        	    if($('#chatbutton').hasClass('active')) {
        	        app.showChat();
        	    } else {
                    app.hideChat();
        	    }
        	});
	
        	$('#helpbutton').click(function() {
                app.toggleAbout();
        	});
	
        	$('#achievementsbutton').click(function() {
                app.toggleAchievements();
                if(app.blinkInterval) {
                    clearInterval(app.blinkInterval);
                }
                $(this).removeClass('blink');
        	});
	
        	$('#inventorybutton').click(function() {
                app.toggleInventory();
        	});

        	$('#instructions').click(function() {
                app.hideWindows();
        	});
        	
        	$('#playercount').click(function() {
        	    app.togglePopulationInfo();
        	});
        	
        	$('#population').click(function() {
        	    app.togglePopulationInfo();
        	});
	
        	$('.clickable').click(function(event) {
                event.stopPropagation();
        	});
	
        	$('#toggle-credits').click(function() {
        	    app.toggleCredits();
        	});
	
        	$('#create-new span').click(function() {
        	    app.animateParchment('loadcharacter', 'confirmation');
        	});
	
        	$('.delete').click(function() {
                app.storage.clear();
        	    app.animateParchment('confirmation', 'createcharacter');
        	});
	
        	$('#cancel span').click(function() {
        	    app.animateParchment('confirmation', 'loadcharacter');
        	});
        	
        	$('.ribbon').click(function() {
        	    app.toggleAbout();
        	});

            $('#nameinput').bind("keyup", function() {
                app.toggleButton();
            });
    
            $('#previous').click(function() {
                var $achievements = $('#achievements');
        
                if(app.currentPage === 1) {
                    return false;
                } else {
                    app.currentPage -= 1;
                    $achievements.removeClass().addClass('active page' + app.currentPage);
                }
            });
    
            $('#next').click(function() {
                var $achievements = $('#achievements'),
                    $lists = $('#lists'),
                    nbPages = $lists.children('ul').length;
        
                if(app.currentPage === nbPages) {
                    return false;
                } else {
                    app.currentPage += 1;
                    $achievements.removeClass().addClass('active page' + app.currentPage);
                }
            });

            $('#notifications div').bind(TRANSITIONEND, app.resetMessagesPosition.bind(app));
    
            $('.close').click(function() {
                app.hideWindows();
            });
        
            $('.twitter').click(function() {
                var url = $(this).attr('href');

               app.openPopup('twitter', url);
               return false;
            });

            $('.facebook').click(function() {
                var url = $(this).attr('href');

               app.openPopup('facebook', url);
               return false;
            });
        
            var data = app.storage.data;
    		if(data.hasAlreadyPlayed) {
    		    if(data.player.name && data.player.name !== "") {
		            $('#playername').html(data.player.name);
    		        $('#playerimage').attr('src', data.player.image);
    		    }
    		}
    		
    		$('.play div').click(function(event) {
                var nameFromInput = $('#nameinput').val(),
                    nameFromStorage = $('#playername').html(),
                    name = nameFromInput || nameFromStorage;
               
                app.tryStartingGame(name);
            });
        
            document.addEventListener("touchstart", function() {},false);
            
            $('#resize-check').bind("transitionend", app.resizeUi.bind(app));
            $('#resize-check').bind("webkitTransitionEnd", app.resizeUi.bind(app));
            $('#resize-check').bind("oTransitionEnd", app.resizeUi.bind(app));
        
            log.info("App initialized.");
        
            initGame();
        });
    };
    
    var initGame = function() {
        require(['game'], function(Game) {
            var canvas = document.getElementById("entities"),
        	    background = document.getElementById("background"),
        	    foreground = document.getElementById("foreground"),
        	    input = document.getElementById("chatinput");
    		game = new Game(app);
            globalGame = game;
    		game.setup('#bubbles', canvas, background, foreground, input);
    		game.setStorage(app.storage);
    		app.setGame(game);
    		
    		if(app.isDesktop && app.supportsWorkers) {
    		    game.loadMap();
    		}
	
            $('#nameinput').val('');
    		$('#chatbox').val('');
    		
        	if(game.renderer.mobile || game.renderer.tablet) {
                $('#foreground').bind('touchstart', function(event) {
                    app.center();
                    app.setMouseCoordinates(event.originalEvent.touches[0]);
                	game.click();
                	app.hideWindows();
                });
            } else {
                $('#foreground').click(function(event) {
                    app.center();
                    app.setMouseCoordinates(event);
                    if (game) {
                	    game.click();
                	}
                	app.hideWindows();
                    // $('#chatinput').focus();
                });
            }

            $('body').unbind('click');
            $('body').click(function(event) {
                var hasClosedParchment = false;
                
                if($('#parchment').hasClass('credits')) {
                    if(game.started) {
                        app.closeInGameCredits();
                        hasClosedParchment = true;
                    } else {
                        app.toggleCredits();
                    }
                }
                
                if($('#parchment').hasClass('about')) {
                    if(game.started) {
                        app.closeInGameAbout();
                        hasClosedParchment = true;
                    } else {
                        app.toggleAbout();
                    }
                }
                
                if(game.started && !game.renderer.mobile && game.player && !hasClosedParchment) {
                    game.click();
                }
            });
            
            $('#respawn').click(function(event) {
                game.audioManager.playSound("revive");
                game.restart();
                $('body').removeClass('death');
            });
            
            $(document).mousemove(function(event) {
            	app.setMouseCoordinates(event);
            	if(game.started) {
            	    game.movecursor();
            	}
            });

            $(document).keyup(function(e) {
            	var key = e.which,
                    $chat = $('#chatinput');

                if (game.started && game.player && !$('#chatbox').hasClass('active')) {
                    switch(key) {
                        case Types.Keys.LEFT:
                        case Types.Keys.A:
                            game.player.moveLeft = false;
                            break;
                        case Types.Keys.RIGHT:
                        case Types.Keys.D:
                            game.player.moveRight = false;
                            break;
                        case Types.Keys.UP:
                        case Types.Keys.W:
                            game.player.moveUp = false;
                            break;
                        case Types.Keys.DOWN:
                        case Types.Keys.S:
                            game.player.moveDown = false;
                            break;
                    }
                }
            });

            $(document).keydown(function(e) {
            	var key = e.which,
                    $chat = $('#chatinput');

                if(key === Types.Keys.ENTER) {
                    if($('#chatbox').hasClass('active')) {
                        app.hideChat();
                    } else {
                        app.showChat();
                    }
                }
                if (game.started && !$('#chatbox').hasClass('active'))
                {
                    var knownKeybinding = true;
                    switch(key) {
                        case Types.Keys.ESC:
                            game.player.target = null;
                            app.hideWindows();
                            _.each(game.player.attackers, function(attacker) {
                                attacker.stop();
                            });
                            break;
                        case Types.Keys.LEFT:
                        case Types.Keys.A:
                            game.player.moveLeft = true;
                            break;
                        case Types.Keys.RIGHT:
                        case Types.Keys.D:
                            game.player.moveRight = true;
                            break;
                        case Types.Keys.UP:
                        case Types.Keys.W:
                            game.player.moveUp = true;
                            break;
                        case Types.Keys.DOWN:
                        case Types.Keys.S:
                            game.player.moveDown = true;
                            break;
                        case Types.Keys.TAB:
                            if (e.shiftKey) {
                                game.player.target = game.player;
                            } else {
                                game.makePlayerTargetNearestEnemy();
                            }
                            break;
                        case Types.Keys.SPACE:
                            game.makePlayerAttackNext();
                            break;
                        case Types.Keys.I:
                            $('#inventorybutton').click();
                            break;
                        case Types.Keys.K:
                            $('#achievementsbutton').click();
                            break;
                        case Types.Keys.H:
                            $('#helpbutton').click();
                            break;
                        case Types.Keys.M:
                            $('#mutebutton').click();
                            break;
                        case Types.Keys.P:
                            $('#playercount').click();
                            break;
                        case Types.Keys.T:
                            game.makePlayerAttackTarget();
                            break;
                        case Types.Keys.Y:
                            game.activateTownPortal();
                            break;
                        case Types.Keys.F:
                            game.player.skillbar.reset();
                            game.player.skillbar.add(Types.Entities.FROSTNOVA);
                            game.player.skillbar.add(Types.Entities.FROSTBOLT);
                            game.player.skillbar.add(Types.Entities.FIREBALL);
            
                            game.toggleDebugInfo();
                            game.togglePathingGrid();
                            break;
                        default:
                            if (game.player && game.player.skillbar.click(key, game.player.target)) {
                                // was a skillbar action
                            } else {
                                knownKeybinding = false;
                            }
                            break;
                    }

                    if (knownKeybinding) {
                        e.preventDefault();
                        return false;
                    }
                }
            });
            
            $('#chatinput').keydown(function(e) {
                var key = e.which,
                    $chat = $('#chatinput');

                if(key === 13) {
                    if($chat.val() !== '') {
                        if (game.player) {
                            game.say($chat.val());
                        }
                        $chat.val('');
                        app.hideChat();
                        $('#foreground').focus();
                        return false;
                    } else {
                        app.hideChat();
                        return false;
                    }
                }
                
                if(key === 27) {
                    app.hideChat();
                    return false;
                }
            });

            $('#nameinput').keypress(function(event) {
                var $name = $('#nameinput'),
                    name = $name.val();

                if(event.keyCode === 13) {
                    if(name !== '') {
                        app.tryStartingGame(name, function() {
                            $name.blur(); // exit keyboard on mobile
                        });
                        return false; // prevent form submit
                    } else {
                        return false; // prevent form submit
                    }
                }
            });
            
            $('#mutebutton').click(function() {
                game.audioManager.toggle();
            });
            
            if(game.renderer.tablet) {
                $('body').addClass('tablet');
            }
        });
    };
    
    initApp();
});
