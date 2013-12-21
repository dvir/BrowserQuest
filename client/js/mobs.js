define(['mob', 'timer'], function (Mob, Timer) {

  var Mobs = {
    Rat: Mob.extend({
      init: function (id) {
        this._super(id, Types.Entities.RAT);
        this.moveSpeed = 350;
        this.idleSpeed = 700;
        this.shadowOffsetY = -2;
        this.isAggressive = false;

        this._name = "Rat";
        this.nameOffsetY += 5;
      }
    }),

    Skeleton: Mob.extend({
      init: function (id) {
        this._super(id, Types.Entities.SKELETON);
        this.moveSpeed = 350;
        this.atkSpeed = 100;
        this.idleSpeed = 800;
        this.shadowOffsetY = 1;
        this.setAttackRate(1300);

        this._name = "Skeleton";
      }
    }),

    Skeleton2: Mob.extend({
      init: function (id) {
        this._super(id, Types.Entities.SKELETON2);
        this.moveSpeed = 200;
        this.atkSpeed = 100;
        this.idleSpeed = 800;
        this.walkSpeed = 200;
        this.shadowOffsetY = 1;
        this.setAttackRate(1300);

        this._name = "Skeleton Warrior";
        this.nameOffsetY -= 2;
      }
    }),

    Spectre: Mob.extend({
      init: function (id) {
        this._super(id, Types.Entities.SPECTRE);
        this.moveSpeed = 150;
        this.atkSpeed = 50;
        this.idleSpeed = 200;
        this.walkSpeed = 200;
        this.shadowOffsetY = 1;
        this.setAttackRate(900);

        this._name = "Spectre";
      }
    }),

    Deathknight: Mob.extend({
      init: function (id) {
        this._super(id, Types.Entities.DEATHKNIGHT);
        this.atkSpeed = 50;
        this.moveSpeed = 220;
        this.walkSpeed = 100;
        this.idleSpeed = 450;
        this.setAttackRate(800);
        this.aggroRange = 3;

        this._name = "Death Knight";
        this.nameOffsetY -= 3;
      },

      idle: function (orientation) {
        if (!this.hasTarget()) {
          this._super(Types.Orientations.DOWN);
        } else {
          this._super(orientation);
        }
      }
    }),

    Goblin: Mob.extend({
      init: function (id) {
        this._super(id, Types.Entities.GOBLIN);
        this.moveSpeed = 150;
        this.atkSpeed = 60;
        this.idleSpeed = 600;
        this.setAttackRate(700);

        this._name = "Goblin";
      }
    }),

    Ogre: Mob.extend({
      init: function (id) {
        this._super(id, Types.Entities.OGRE);
        this.moveSpeed = 300;
        this.atkSpeed = 100;
        this.idleSpeed = 600;

        this._name = "Ogre";
        this.nameOffsetY -= 6;
      }
    }),

    Crab: Mob.extend({
      init: function (id) {
        this._super(id, Types.Entities.CRAB);
        this.moveSpeed = 200;
        this.atkSpeed = 40;
        this.idleSpeed = 500;

        this._name = "Crab";
      }
    }),

    Snake: Mob.extend({
      init: function (id) {
        this._super(id, Types.Entities.SNAKE);
        this.moveSpeed = 200;
        this.atkSpeed = 40;
        this.idleSpeed = 250;
        this.walkSpeed = 100;
        this.shadowOffsetY = -4;

        this._name = "Snake";
      }
    }),

    Eye: Mob.extend({
      init: function (id) {
        this._super(id, Types.Entities.EYE);
        this.moveSpeed = 200;
        this.atkSpeed = 40;
        this.idleSpeed = 50;

        this._name = "Eye";
      }
    }),

    Bat: Mob.extend({
      init: function (id) {
        this._super(id, Types.Entities.BAT);
        this.moveSpeed = 120;
        this.atkSpeed = 90;
        this.idleSpeed = 90;
        this.walkSpeed = 85;
        this.isAggressive = false;

        this._name = "Bat";
      }
    }),

    Wizard: Mob.extend({
      init: function (id) {
        this._super(id, Types.Entities.WIZARD);
        this.moveSpeed = 200;
        this.atkSpeed = 100;
        this.idleSpeed = 150;

        this._name = "Wizard";
      }
    }),

    Boss: Mob.extend({
      init: function (id) {
        this._super(id, Types.Entities.BOSS);
        this.moveSpeed = 300;
        this.atkSpeed = 50;
        this.idleSpeed = 400;
        this.atkRate = 2000;
        this.attackCooldown = new Timer(this.atkRate);
        this.aggroRange = 3;

        this._name = "Skeleton King";
        this.nameOffsetY -= 14;
      },

      idle: function (orientation) {
        if (!this.hasTarget()) {
          this._super(Types.Orientations.DOWN);
        } else {
          this._super(orientation);
        }
      }
    })
  };

  return Mobs;
});
