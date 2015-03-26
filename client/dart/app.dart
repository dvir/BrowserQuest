library app;

import "dart:async";
import 'dart:html' hide Player;
import 'dart:math';

import 'achievements.dart';
import 'base.dart';
import 'character.dart';
import 'config.dart';
import 'entity.dart';
import 'game.dart';
import 'healthbar.dart';
import 'player.dart';
import 'position.dart';
import 'xpbar.dart';
import "lib/gametypes.dart";

class Application extends Base {

  bool isDesktop = true;
  bool supportsWorkers = true;
  int currentPage = 0;
  bool isParchmentReady = true;
  Timer messageTimer;
  Timer blinkTimer;
  String previousState;
  HealthBar playerHealthBar;
  HealthBar targetHealthBar;
  XPBar xpBar;
  
  void center() {
    window.scrollTo(0, 1);
  }
  
  void setMouseCoordinates(MouseEvent event) {
    Rectangle gamePos = document.getElementById('container').offset;

    Game.mouse = new Position(
      ((event.page.x - gamePos.left - (5 * Game.renderer.getScaleFactor())) as num).clamp(0, Game.renderer.width - 1), 
      ((event.page.y - gamePos.top - (7 * Game.renderer.getScaleFactor())) as num).clamp(0, Game.renderer.height - 1)
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

  void initEquipmentIcons() {
    window.console.log("initEquipmentIcons");
    Game.player.on("ArmorChange", () {
      if (Game.player.armor == Entities.FIREFOX) { 
        return;
      }

      int scale = Game.renderer.getScaleFactor();
      String armorName = Types.getKindAsString(Game.player.armor);
      document.getElementById('armor').style.backgroundImage =
        'url("img/${scale}/item-${armorName}.png")';
    });

    Game.player.on("WeaponChange", () {
      int scale = Game.renderer.getScaleFactor();
      String weaponName = Types.getKindAsString(Game.player.weapon);
      document.getElementById('weapon').style.backgroundImage =
        'url("img/${scale}/item-${weaponName}.png")';
    });
  }

  // TODO(inventory): implement or remove. the relevant code is complicated
  void updateInventory() {}

  // TODO(skillbar): implement or remove. the relevant code is complicated
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
    Element $element = document.getElementById("player");
    Element $bar = $element.querySelector(".healthbar");
    Element $progress = $element.querySelector(".hitpoints");
    this.playerHealthBar = new HealthBar($element, $bar, $progress);
    this.playerHealthBar.setTarget(Game.player);
  }

  void initXPBar() {
    Element $element = document.getElementById("xp-container");
    Element $bar = document.getElementById("xpbar");
    Element $progress = document.getElementById("xp");
    this.xpBar = new XPBar(Game.player, $element, $bar, $progress);

    Element $level = document.getElementById("level");
    void updateLevel() {
      $level.innerHtml = Game.player.level.toString();
    }
    Game.events.onAndExecute("LevelChange", updateLevel);
  }

  void initTargetBar() {
    Element $element = document.getElementById("target");
    Element $bar = $element.querySelector(".healthbar");
    Element $progress = $element.querySelector(".hitpoints");
    this.targetHealthBar = new HealthBar($element, $bar, $progress);

    Game.events.on("TargetChange", () {
      Entity target = Game.player.target;
      this.targetHealthBar.setTarget(target is Character ? target : null);
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
    // if the achievements icon was flashing (happens when the player achieves
    // the first achievement), turn the flashing off
    if (this.blinkTimer != null) {
      this.blinkTimer.cancel();
      this.blinkTimer = null;
      document.getElementById('achievementsbutton').classes.remove('blink');
    }

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
          if (Game.storage.hasAlreadyPlayed) {
            this.animateParchment(currentState, 'loadcharacter');
          } else {
            this.animateParchment(currentState, 'createcharacter');
          }
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

  void setAchievementData(Element $el, Achievement achievement) {
    $el.querySelector('.achievement-name').innerHtml = achievement.name;
    $el.querySelector('.achievement-description').innerHtml = achievement.description;
  }

  void initAchievementList() {
    Element $lists = document.getElementById('lists');
    Element $page = document.getElementById('page-tmpl');
    Element $achievement = document.getElementById('achievement-tmpl');
    Element $p = null;
    int page = 0;
    int count = 0;

    Achievement.forEach((Achievement achievement) {
      count++;

      Element $a = $achievement.clone(true);
      $a.setAttribute('id', '');
      $a.classes.add('achievement${count}');
      if (!achievement.hidden) {
        this.setAchievementData($a, achievement);
      }
      $a.querySelector('.twitter').setAttribute('href', 'http://twitter.com/share?url=http%3A%2F%2Fbrowserquest.mozilla.org&text=I%20unlocked%20the%20%27${achievement.name}%27%20achievement%20on%20Mozilla%27s%20%23BrowserQuest%21&related=glecollinet:Creators%20of%20BrowserQuest%2Cwhatthefranck');
      $a.style.display = 'block';
      $a.querySelector('a').addEventListener('click', (Event event) {
        String url = (event.target as LinkElement).href;
        this.openPopup('twitter', url);
        return false;
      });

      if ((count - 1) % 4 == 0) {
        page++;
        $p = $page.clone(true);
        $p.setAttribute('id', 'page${page}');
        $p.style.display = 'block';
        $lists.append($p);
      }
      $p.append($a);
    });

    document.getElementById('total-achievements').innerHtml = '${count}';

    if (Game.storage.hasAlreadyPlayed) {
      this.initUnlockedAchievements();
    }
  }

  void initUnlockedAchievements() {
    int count = 0;
    Achievement.forEach((Achievement achievement) {
      if (!Game.storage.hasUnlockedAchievement(achievement)) {
        return;
      }

      this.displayUnlockedAchievement(achievement);
      count++;
    });

    document.getElementById('unlocked-achievements').innerHtml = '${count}';
  }

  void showAchievementNotification(Achievement achievement) {
    Element $notif = document.getElementById('achievement-notification');
    Element $name = $notif.querySelector('.name');
    Element $button = document.getElementById('achievementsbutton');

    $notif.classes.clear();
    $notif.classes.add('active');
    $notif.classes.add('achievement${achievement.id}');
    $name.innerHtml = achievement.name;
    if (Game.storage.getAchievementCount() == 1) {
      this.blinkTimer = new Timer.periodic(new Duration(milliseconds: 500), (Timer timer) {
        $button.classes.toggle('blink');
      });
    }
    new Timer(new Duration(seconds: 5), () {
      $notif.classes.remove('active');
      $button.classes.remove('blink');
    });
  }

  void displayUnlockedAchievement(Achievement achievement) {
    Element $achievement = document.getElementById('achievements').querySelector('li.achievement${achievement.id}');
    if (achievement.hidden) {
      this.setAchievementData($achievement, achievement);
    }
    $achievement.classes.add('unlocked');
  }

  void unlockAchievement(Achievement achievement) {
    this.showAchievementNotification(achievement);
    this.displayUnlockedAchievement(achievement);

    Element unlockedCount = document.getElementById('unlocked-achievements');
    unlockedCount.innerHtml = '${int.parse(unlockedCount.innerHtml) + 1}';
  }

  void openPopup(type, url) {
    int h = window.innerHeight;
    int w = window.innerWidth;
    int popupHeight;
    int popupWidth;
    num top;
    num left;

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

    window.open(url, 'name', 'height=${popupHeight},width=${popupWidth},top=${top},left=${left}');
  }

  void animateParchment(origin, destination) {
    Element parchment = document.getElementById('parchment');
    int duration = 1;

    if (!this.isParchmentReady) {
      return;
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
    bool firstTimePlaying = !Game.storage.hasAlreadyPlayed;

    if (username.isEmpty) {
      throw new Exception('Cannot start the game with an empty username');
    }

    window.console.debug("Starting game with build config.");
    Game.setServerOptions(ServerConfig.host, ServerConfig.port, username);

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
      this.start(username);
    });
  }
  
  void tryStartingGame(String username, [Function starting_callback]) {
    if (username.isEmpty) {
      return;
    }
    
    Element playButton = document.querySelector('.play');
    
    if (!this.canStartGame) {
      // add a spinner to the play button
      playButton.classes.add('loading');
      window.console.debug("waiting...");
      this.on('start', () {
        new Timer(new Duration(milliseconds: 1500), () {
          playButton.classes.remove('loading');
        });
        
        this.startGame(username, starting_callback);
      }, true);
    } else {
      this.startGame(username, starting_callback);
    }
  }
  
  bool get canStartGame => Game.map.isLoaded;
}
