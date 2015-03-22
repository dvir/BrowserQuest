library mobs;

import "mob.dart";
import "lib/gametypes.dart";

class Rat extends Mob {

  Rat(int id): super(id, Entities.RAT) {
    this.name = "Rat";
    this.moveSpeed = 350;
    this.idleSpeed = 700;
    this.shadowOffsetY = -2;
    this.isAggressive = false;
    this.nameOffsetY += 5;
  }
}

class Skeleton extends Mob {

  Skeleton(int id): super(id, Entities.SKELETON) {
    this.name = "Skeleton";
    this.moveSpeed = 350;
    this.atkSpeed = 100;
    this.idleSpeed = 800;
    this.shadowOffsetY = 1;
    this.attackRate = 1300;
  }
}

class SkeletonWarrior extends Mob {

  SkeletonWarrior(int id): super(id, Entities.SKELETON2) {
    this.name = "Skeleton Warrior";
    this.nameOffsetY -= 2;
    this.moveSpeed = 200;
    this.atkSpeed = 100;
    this.idleSpeed = 800;
    this.walkSpeed = 200;
    this.shadowOffsetY = 1;
    this.attackRate = 1300;
  }
}

class Spectre extends Mob {

  Spectre(int id): super(id, Entities.SPECTRE) {
    this.name = "Spectre";
    this.moveSpeed = 150;
    this.atkSpeed = 50;
    this.idleSpeed = 200;
    this.walkSpeed = 200;
    this.shadowOffsetY = 1;
    this.attackRate = 900;
  }
}

class Deathknight extends Mob {

  Deathknight(int id): super(id, Entities.DEATHKNIGHT) {
    this.name = "Death Knight";
    this.nameOffsetY -= 3;
    this.atkSpeed = 50;
    this.moveSpeed = 220;
    this.walkSpeed = 100;
    this.idleSpeed = 450;
    this.attackRate = 800;
    this.aggroRange = 3;
  }

  void idle([Orientation orientation]) {
    if (!this.hasTarget()) {
      super.idle(Orientation.DOWN);
    } else {
      super.idle(orientation);
    }
  }
}

class Goblin extends Mob {

  Goblin(int id): super(id, Entities.GOBLIN) {
    this.name = "Goblin";
    this.moveSpeed = 150;
    this.atkSpeed = 60;
    this.idleSpeed = 600;
    this.attackRate = 700;
  }
}

class Ogre extends Mob {

  Ogre(int id): super(id, Entities.OGRE) {
    this.name = "Ogre";
    this.nameOffsetY -= 6;
    this.moveSpeed = 300;
    this.atkSpeed = 100;
    this.idleSpeed = 600;
  }
}

class Crab extends Mob {

  Crab(int id): super(id, Entities.CRAB) {
    this.name = "Crab";
    this.moveSpeed = 200;
    this.atkSpeed = 40;
    this.idleSpeed = 500;
  }
}

class Snake extends Mob {

  Snake(int id): super(id, Entities.SNAKE) {
    this.name = "Snake";
    this.moveSpeed = 200;
    this.atkSpeed = 40;
    this.idleSpeed = 250;
    this.walkSpeed = 100;
    this.shadowOffsetY = -4;
  }
}

class Eye extends Mob {

  Eye(int id): super(id, Entities.EYE) {
    this.name = "Eye";
    this.moveSpeed = 200;
    this.atkSpeed = 40;
    this.idleSpeed = 50;
  }
}

class Bat extends Mob {

  Bat(int id): super(id, Entities.BAT) {
    this.name = "Bat";
    this.moveSpeed = 120;
    this.atkSpeed = 90;
    this.idleSpeed = 90;
    this.walkSpeed = 85;
    this.isAggressive = false;
  }
}

class Wizard extends Mob {

  Wizard(int id): super(id, Entities.WIZARD) {
    this.name = "Wizard";
    this.moveSpeed = 200;
    this.atkSpeed = 100;
    this.idleSpeed = 150;
  }
}

class Boss extends Mob {

  Boss(int id): super(id, Entities.BOSS) {
    this.name = "Skeleton King";
    this.nameOffsetY -= 14;
    this.moveSpeed = 300;
    this.atkSpeed = 50;
    this.idleSpeed = 400;
    this.aggroRange = 3;
    this.attackRate = 2000;
  }

  void idle([Orientation orientation]) {
    if (!this.hasTarget()) {
      super.idle(Orientation.DOWN);
    } else {
      super.idle(orientation);
    }
  }
}
