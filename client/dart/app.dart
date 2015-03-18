library app;

import "dart:async";
import 'dart:html' hide Player;
import 'dart:math';

import 'base.dart';
import 'config.dart';
import 'entity.dart';
import 'game.dart';
import 'healthbar.dart';
import 'player.dart';
import 'position.dart';

class Application extends Base {

  Config config = new Config();
  bool isDesktop = true;
  bool isMobile = false;
  bool isTablet = false;
  bool supportsWorkers = true;
  int currentPage = 0;
  bool isParchmentReady = true;
  Timer messageTimer;
  // TODO: can probably be removed after factoring out
  String previousState;
  
  void center() {
    window.scrollTo(0, 1);
  }
  
  void setMouseCoordinates(MouseEvent event) {
    Rectangle gamePos = document.getElementById('container').offset;

    Game.mouse = new Position(
      ((event.page.x - gamePos.left - (this.isMobile ? 0 : 5 * Game.renderer.getScaleFactor())) as num).clamp(0, Game.renderer.width - 1), 
      ((event.page.y - gamePos.top - (this.isMobile ? 0 : 7 * Game.renderer.getScaleFactor())) as num).clamp(0, Game.renderer.height - 1)
    );
  }

  void playerDeath() {
    Element body = document.querySelector('body');
    body.classes.remove('credits');
    body.classes.add('death');
  }

  void playerInvincible(bool state) {
    document.querySelector('#player > .hitpoints').classes.toggle('invincible', state);
  }

  // TODO: implement
  void initEquipmentIcons() {
    window.console.log("initEquipmentIcons");
  }

  // TODO: implement or remove. the relevant code is complicated
  void updateInventory() {}
  void updateSkillbar() {}

  void disconnected(String message) {
    document.querySelector('#death p').innerHtml = "${message} <em>Please reload the page.</em>";
    document.getElementById('respawn').style.display = 'none';
  }

  void initBars() {
    this.initEquipmentIcons();
    this.initHealthBar();
    this.initXPBar();
    this.initTargetBar();
  }

  void initHealthBar() {
    Healthbar healthbar = new Healthbar(document.getElementById("player"), Game.player);

    Game.events.on("HealthChange", () {
      healthbar.update();
    });
  }

  void initXPBar() {
    Game.events.on("XPChange", () {
      Element xpBar = document.getElementById('xpbar');
      Player player = Game.player;

      int barWidth = player.maxXP > 0 ? (player.xp * 100 / player.maxXP).round() : 0;
      xpBar.innerHtml = "${player.xp}/${player.maxXP}";
      document.getElementById("xp").style.width = "${barWidth}%";
      document.getElementById("level").innerHtml = player.level.toString();
    });
  }

  void initTargetBar() {
    Element $target = document.getElementById("target");

    Game.events.on("TargetChange", () {
      Entity target = Game.player.target;

      if (target == null) {
        $target.style.display = 'none';
        return;
      }

      $target.style.display = 'block';
      Healthbar healthbar = new Healthbar($target, target);
      target.on("change", () {
        healthbar.update();
      });
    });
  }
  
  void hideWindows() {
    if (document.getElementById('achievements').classes.contains('active')) {
      this.toggleAchievements();
      document.getElementById('achievementsbutton').classes.remove('active');
    }
    if (document.getElementById('instructions').classes.contains('active')) {
      this.toggleInstructions();
      document.getElementById('helpbutton').classes.remove('active');
    }
    if (document.getElementById('inventory').classes.contains('active')) {
      this.toggleInventory();
      document.getElementById('inventorybutton').classes.remove('active');
    }
    if (document.querySelector('body').classes.contains('credits')) {
      this.closeInGameCredits();
    }
    if (document.querySelector('body').classes.contains('about')) {
      this.closeInGameAbout();
    }
  }
  
  toggleButton() {
    String name = (document.querySelector('#parchment input') as InputElement).value;
    Element playButton = document.querySelector('#createcharacter .play');

    if (name.length > 0) {
      playButton.classes.remove('disabled');
      document.getElementById('character').classes.remove('disabled');
    } else {
      playButton.classes.add('disabled');
      document.getElementById('character').classes.add('disabled');
    }
  }

  hideIntro(hidden_callback) {
    Element body = document.querySelector('body');
    body.classes.remove('intro');
    new Timer(new Duration(seconds: 1), () {
      body.classes.add('game');
      hidden_callback();
    });
  }

  showChat([String initial_text = '']) {
    if (!Game.started) {
      return;
    }
    
    document.getElementById('chatbox').classes.add('active');
    InputElement chatInput = document.getElementById('chatinput');
    chatInput.value = initial_text;
    chatInput.focus();
    document.getElementById('chatbutton').classes.add('active');
  }

  hideChat() {
    if (!Game.started) {
      return;
    }
    
    document.getElementById('chatbox').classes.remove('active');
    document.getElementById('chatinput').blur();
    document.getElementById('chatbutton').classes.remove('active');
  }

  toggleInstructions() {
    if (document.getElementById('achievements').classes.contains('active')) {
      this.toggleAchievements();
      document.getElementById('achievementsbutton').classes.remove('active');
    }
    document.getElementById('instructions').classes.toggle('active');
  }

  toggleAchievements() {
    if (document.getElementById('instructions').classes.contains('active')) {
      this.toggleInstructions();
      document.getElementById('helpbutton').classes.remove('active');
    }
    this.resetPage();
    document.getElementById('achievements').classes.toggle('active');
  }

  resetPage() {
    Element achievements = document.getElementById('achievements');

    if (achievements.classes.contains('active')) {
      achievements.onTransitionEnd.first.then((TransitionEvent event) {
        achievements.classes.remove('page${this.currentPage}');
        achievements.classes.add('page1');
        this.currentPage = 1;
      });
    }
  }

  toggleInventory() {
    if (!document.getElementById('inventory').classes.contains('active')) {
      Game.updateInventory();
    }
    document.getElementById('inventory').classes.toggle('active');
  }  
  
  void toggleCredits() {
    Element parchment = document.getElementById('parchment');
    String currentState = parchment.getAttribute('class');

    if (Game.started) {
      parchment.classes.clear();
      parchment.classes.add('credits');

      document.querySelector('body').classes.toggle('credits');

      if (Game.player == null) {
        document.querySelector('body').classes.toggle('death');
      }
      if (document.querySelector('body').classes.contains('about')) {
        this.closeInGameAbout();
        document.getElementById('helpbutton').classes.remove('active');
      }
    } else {
      if (currentState != 'animate') {
        if (currentState == 'credits') {
          this.animateParchment(currentState, this.previousState);
        } else {
          this.animateParchment(currentState, 'credits');
          this.previousState = currentState;
        }
      }
    }
  }

  void toggleAbout() {
    Element parchment = document.getElementById('parchment');
    String currentState = parchment.getAttribute('class');

    if (Game.started) {
      parchment.classes.clear();
      parchment.classes.add('about');
      document.querySelector('body').classes.toggle('about');
      if (Game.player == null) {
        document.querySelector('body').classes.toggle('death');
      }
      if (document.querySelector('body').classes.contains('credits')) {
        this.closeInGameCredits();
      }
    } else {
      if (currentState != 'animate') {
        if (currentState == 'about') {
          // TODO: implement properly
          /*
          if (localStorage && localStorage.data) {
            this.animateParchment(currentState, 'loadcharacter');
          } else {
            this.animateParchment(currentState, 'createcharacter');
          }
          */
          this.animateParchment(currentState, 'createcharacter');
        } else {
          this.animateParchment(currentState, 'about');
          this.previousState = currentState;
        }
      }
    }
  }

  void closeInGameCredits() {
    document.querySelector('body').classes.remove('credits');
    document.getElementById('parchment').classes.remove('credits');
    if (Game.player == null) {
      document.querySelector('body').classes.add('death');
    }
  }

  void closeInGameAbout() {
    document.querySelector('body').classes.remove('about');
    document.getElementById('parchment').classes.remove('about');
    if (Game.player == null) {
      document.querySelector('body').classes.add('death');
    }
    document.getElementById('helpbutton').classes.remove('active');
  }

  void togglePopulationInfo() {
    document.getElementById('population').classes.toggle('visible');
  }

  void openPopup(type, url) {
    var h = window.innerHeight,
      w = window.innerWidth,
      popupHeight,
      popupWidth,
      top,
      left;

    switch (type) {
    case 'twitter':
      popupHeight = 450;
      popupWidth = 550;
      break;
    case 'facebook':
      popupHeight = 400;
      popupWidth = 580;
      break;
    }

    top = (h / 2) - (popupHeight / 2);
    left = (w / 2) - (popupWidth / 2);

    var newwindow = window.open(url, 'name', 'height=' + popupHeight + ',width=' + popupWidth + ',top=' + top + ',left=' + left);
  }

  void animateParchment(origin, destination) {
    Element parchment = document.getElementById('parchment');
    int duration = 1;

    if (this.isMobile) {
      parchment.classes.remove(origin);
      parchment.classes.add(destination);
      return;
    }

    if (!this.isParchmentReady) {
      return;
    }

    if (this.isTablet) {
      duration = 0;
    }

    this.isParchmentReady = !this.isParchmentReady;

    parchment.classes.toggle('animate');
    parchment.classes.remove(origin);

    new Timer(new Duration(seconds: duration), () {
      parchment.classes.toggle('animate');
      parchment.classes.add(destination);
      
      this.isParchmentReady = !this.isParchmentReady;
    });
  }

  void animateMessages() {
    document.querySelector('#notifications div').classes.add('top');
  }

  void resetMessagesPosition() {
    String message = document.getElementById('message2').text;
    document.querySelector('#notifications div').classes.remove('top');
    document.getElementById('message2').text = '';
    document.getElementById('message1').text = message;
  }

  void showMessage(String message) {
    Element wrapper = document.querySelector('#notifications div');
    Element messageElement = document.querySelector('#notifications #message2');

    this.animateMessages();
    messageElement.text = message;
    this.resetMessageTimer();
    this.messageTimer = new Timer(new Duration(milliseconds: 5000), () {
      wrapper.classes.add('top');
    });
  }

  void resetMessageTimer() {
    if (this.messageTimer == null) {
      return;
    }
    
    this.messageTimer.cancel();
    this.messageTimer = null;
  }
  
  void resizeUi() {
    if (Game.started) {
      Game.resize();
      this.initBars();
      Game.updateBars();
      return;
    }
    
    Game.renderer.rescale();
  }
  
  void start(String username) {
    // TODO: implement properly
    //var firstTimePlaying = !this.storage.hasAlreadyPlayed();
    bool firstTimePlaying = true;

    if (username.isEmpty) {
      throw new Exception('Cannot start the game with an empty username');
    }
    
    // TODO: eh? this doesn't make sense
    if (Game.started) {
      throw new Exception('Game.started must equal true before starting it from the app');
    }

    window.console.debug("Starting game with build config.");
    Game.setServerOptions(config.host, config.port, username);

    this.center();
    Game.run(() {
      document.querySelector('body').classes.add('started');
      if (firstTimePlaying) {
        this.toggleInstructions();
      }
    });
  }
  
  void startGame(String username, [Function starting_callback]) {
    if (starting_callback != null) {
      starting_callback();
    }
    this.hideIntro(() {
      if (!this.isDesktop) {
        // On mobile and tablet we load the map after the player has clicked
        // on the PLAY button instead of loading it in a web worker.
        Game.loadMap();
      }
      this.start(username);
    });
  }
  
  void tryStartingGame(String username, [Function starting_callback]) {
    if (username.isEmpty) {
      return;
    }
    
    Element playButton = document.querySelector('.play');
    Element playDiv = playButton.querySelector('div');
    
    if (!this.canStartGame) {
      if (!this.isMobile) {
        // on desktop and tablets, add a spinner to the play button
        playButton.classes.add('loading');
      }
      window.console.debug("waiting...");
      this.on('start', () {
        new Timer(new Duration(milliseconds: 1500), () {
          if (!this.isMobile) {
            playButton.classes.remove('loading');
          }            
        });
        
        this.startGame(username, starting_callback);
      }, true);
    } else {
      this.startGame(username, starting_callback);
    }
  }
  
  bool get canStartGame => Game.map.isLoaded;
}
