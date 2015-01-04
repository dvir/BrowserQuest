library home;

import 'dart:html';

import 'app.dart';
import 'character.dart';
import 'game.dart';
import 'lib/gametypes.dart';

initGame() {
  Element canvas = document.getElementById("entities");
  Element background = document.getElementById("background");
  Element foreground = document.getElementById("foreground");
  Element input = document.getElementById("chatinput");
  Game.setup(new Application(), document.getElementById('bubbles'), canvas, background, foreground, input);
// TODO: implement differently
  //Game.setStorage(Game.app.storage);

  if (Game.app.isDesktop && Game.app.supportsWorkers) {
    Game.loadMap();
  }

  (document.getElementById('nameinput') as InputElement).value = '';
  (document.getElementById('chatinput') as InputElement).value = '';

  document.getElementById('foreground').onClick.listen((event) {
    Game.app.center();
    Game.app.setMouseCoordinates(event);
    Game.click();
    Game.app.hideWindows();
    // document.getElementById('chatinput').focus();
  });
    
  document.querySelector('body').onClick.listen((Event event) {
    bool hasClosedParchment = false;

    if (document.getElementById('parchment').classes.contains('credits')) {
      if (Game.started) {
        Game.app.closeInGameCredits();
        hasClosedParchment = true;
      } else {
        Game.app.toggleCredits();
      }
    }

    if (document.getElementById('parchment').classes.contains('about')) {
      if (Game.started) {
        Game.app.closeInGameAbout();
        hasClosedParchment = true;
      } else {
        Game.app.toggleAbout();
      }
    }

    if (Game.started && !Game.renderer.mobile && Game.player != null && !hasClosedParchment) {
      Game.click();
    }
    
    return false;
  });

  document.getElementById('respawn').onClick.listen((event) {
    Game.audioManager.playSound("revive");
    Game.restart();
    document.querySelector('body').classes.remove('death');
  });

  document.onMouseMove.listen((event) {
    Game.app.setMouseCoordinates(event);
    if (Game.started) {
      Game.updateHoverTargets();
    }
  });

  document.onKeyDown.listen((KeyboardEvent event) {
    int key = event.which;
    Element chat = document.getElementById('chatinput');

    if (Game.started && !document.getElementById('chatbox').classes.contains('active')) {
      var knownKeybinding = true;
      switch (Keys.get(key)) {
        case Key.ENTER:
          Game.app.showChat();
          break;

        case Key.SLASH:
          Game.app.showChat("/");
          break;

        case Key.ESC:
          Game.player.target = null;
          Game.app.hideWindows();
          // TODO: wait what? are we stopping OTHER attackers?
          Game.player.attackers.forEach((_, Character attacker) {
            attacker.stop();
          });
          break;

        case Key.LEFT:
        case Key.A:
          Game.player.direction = Orientation.LEFT;
          break;
          
        case Key.RIGHT:
        case Key.D:
          Game.player.direction = Orientation.RIGHT;
          break;
          
        case Key.UP:
        case Key.W:
          Game.player.direction = Orientation.UP;
          break;
          
        case Key.DOWN:
        case Key.S:
          Game.player.direction = Orientation.DOWN;
          break;        

        case Key.TAB:
          if (event.shiftKey) {
            Game.player.target = Game.player;
          } else {
            Game.makePlayerTargetNearestEnemy();
          }
          break;

        case Key.SPACE:
          Game.makePlayerAttackNext();
          break;

        case Key.I:
          document.getElementById('inventorybutton').click();
          break;

        case Key.K:
          document.getElementById('achievementsbutton').click();
          break;

        case Key.H:
          document.getElementById('helpbutton').click();
          break;

        case Key.M:
          document.getElementById('mutebutton').click();
          break;

        case Key.P:
          document.getElementById('playercount').click();
          break;

        case Key.T:
          Game.makePlayerAttackTarget();
          break;

        case Key.Y:
          Game.activateTownPortal();
          break;

        case Key.F:
          Game.player.skillbar.reset();
          Game.player.skillbar.add(Entities.FROSTNOVA);
          Game.player.skillbar.add(Entities.FROSTBOLT);
          Game.player.skillbar.add(Entities.FIREBALL);

          Game.toggleDebugInfo();
          Game.togglePathingGrid();
          break;

        default:
          if (Game.player != null && Game.player.skillbar.click(key, Game.player.target)) {
            // was a skillbar action
          } else {
            knownKeybinding = false;
          }
          break;
      }

      if (knownKeybinding) {
        event.preventDefault();
        return false;
      }
    }
  });

  document.getElementById('chatinput').onKeyDown.listen((KeyboardEvent event) {
    int key = event.which;
    InputElement chat = document.getElementById('chatinput');

    switch(Keys.get(key)) {
      case Key.ENTER:
        if (chat.value != '') {
          if (Game.player != null) {
            Game.say(chat.value);
          }
          chat.value = '';
          Game.app.hideChat();
          document.getElementById('foreground').focus();
          return false;
        }
        
        Game.app.hideChat();
        return false;
       
      case Key.ESC:
        Game.app.hideChat();
        return false;
    }
  });

  document.getElementById('nameinput').onKeyPress.listen((KeyboardEvent event) {
    InputElement nameElement = document.getElementById('nameinput');
    String name = nameElement.value;

    if (event.keyCode != Key.ENTER) {
      return true;
    }
    
    if (name != '') {
      Game.app.tryStartingGame(name, () {
        nameElement.blur(); // exit keyboard on mobile
      });
    }
    
    return false; // prevent form submit
  });

  document.getElementById('mutebutton').onClick.listen((Event event) {
    Game.audioManager.toggle();
  });

  if (Game.renderer.tablet) {
    document.querySelector('body').classes.add('tablet');
  }
}

void main() {
  window.console.log('Started');
  initGame();
  Game.app.center();

  // TODO: figure out alternative or remove
  /*
  if (Detect.isWindows()) {
    // Workaround for graphical glitches on text
    document.querySelector('body').classes.add('windows');
  }

  if (Detect.isOpera()) {
    // Fix for no pointer events
    document.querySelector('body').classes.add('opera');
  }
  */

  document.querySelector('body').onClick.listen((event) {
    if (document.getElementById('parchment').classes.contains('credits')) {
      Game.app.toggleCredits();
    }

    if (document.getElementById('parchment').classes.contains('about')) {
      Game.app.toggleAbout();
    }
  });

  document.querySelector('.barbutton').onClick.listen((Event event) {
    (event.target as Element).classes.toggle('active');
  });

  document.getElementById('chatbutton').onClick.listen((Event event) {
    if (document.getElementById('chatbutton').classes.contains('active')) {
      Game.app.showChat();
    } else {
      Game.app.hideChat();
    }
  });

  document.getElementById('helpbutton').onClick.listen((Event event) {
    Game.app.toggleAbout();
  });

  document.getElementById('achievementsbutton').onClick.listen((Event event) {
    Game.app.toggleAchievements();
    // TODO: implement or remove
    /*
    if (Game.app.blinkInterval) {
      clearInterval(Game.app.blinkInterval);
    }
    */
    (event.target as Element).classes.remove('blink');
  });

  document.getElementById('inventorybutton').onClick.listen((Event event) {
    Game.app.toggleInventory();
  });

  document.getElementById('instructions').onClick.listen((Event event) {
    Game.app.hideWindows();
  });

  document.getElementById('playercount').onClick.listen((Event event) {
    Game.app.togglePopulationInfo();
  });

  document.getElementById('population').onClick.listen((Event event) {
    Game.app.togglePopulationInfo();
  });

  document.querySelector('.clickable').onClick.listen((event) {
    event.stopPropagation();
  });

  document.getElementById('toggle-credits').onClick.listen((Event event) {
    Game.app.toggleCredits();
  });

  document.querySelector('#create-new span').onClick.listen((Event event) {
    Game.app.animateParchment('loadcharacter', 'confirmation');
  });

  document.querySelector('.delete').onClick.listen((Event event) {
    // TODO: implement properly
    //Game.app.storage.clear();
    Game.app.animateParchment('confirmation', 'createcharacter');
  });

  document.querySelector('#cancel span').onClick.listen((Event event) {
    Game.app.animateParchment('confirmation', 'loadcharacter');
  });

  document.querySelector('.ribbon').onClick.listen((Event event) {
    Game.app.toggleAbout();
  });

  document.getElementById('nameinput').onKeyUp.listen((KeyboardEvent event) {
    Game.app.toggleButton();
  });

  document.getElementById('previous').onClick.listen((Event event) {
    Element achievements = document.getElementById('achievements');

    if (Game.app.currentPage == 1) {
      return false;
    }
    
    Game.app.currentPage -= 1;
    achievements.classes.clear();
    achievements.classes.add('active page${Game.app.currentPage}');
  });

  document.getElementById('next').onClick.listen((Event event) {
    Element achievements = document.getElementById('achievements');
    Element lists = document.getElementById('lists');
    int nbPages = lists.querySelectorAll('ul').length;

    if (Game.app.currentPage == nbPages) {
      return false;
    }
    
    Game.app.currentPage += 1;
    achievements.classes.clear();
    achievements.classes.add('active page${Game.app.currentPage}');
  });

  document.querySelector('#notifications div').onTransitionEnd.listen((_) => Game.app.resetMessagesPosition);

  document.querySelector('.close').onClick.listen((Event event) {
    Game.app.hideWindows();
  });

  document.querySelector('.twitter').onClick.listen((Event event) {
    Game.app.openPopup('twitter', (event.target as Element).getAttribute('href'));
    return false;
  });

  document.querySelector('.facebook').onClick.listen((Event event) {
    Game.app.openPopup('facebook', (event.target as Element).getAttribute('href'));
    return false;
  });

  // TODO: implement properly
  /*
  var data = Game.app.storage.data;
  if (data.hasAlreadyPlayed) {
    if (data.player.name && data.player.name != "") {
      document.getElementById('playername').html(data.player.name);
      document.getElementById('playerimage').attr('src', data.player.image);
    }
  }
  */

  document.querySelector('.play div').onClick.listen((Event event) {
    Game.app.tryStartingGame((document.getElementById('nameinput') as InputElement).value);
  });

  document.onTouchStart.listen((Event event) {});

  document.getElementById('resize-check').onTransitionEnd.listen((_) => Game.app.resizeUi);

  window.console.info("App initialized.");
}
