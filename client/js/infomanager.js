define(['../../shared/js/gametypes'], function () {

  var InfoManager = Class.extend({
    init: function (game) {
      this.game = game;
      this.infos = {};
      this.destroyQueue = [];
    },

    addDamageInfo: function (value, x, y, type) {
      var time = this.game.currentTime,
        id = time + "" + Math.abs(value) + "" + x + "" + y,
        self = this,
        info = new DamageInfo(id, value, x, y, DamageInfo.DURATION, type);

      info.onDestroy(function (id) {
        self.destroyQueue.push(id);
      });
      this.infos[id] = info;
    },

    forEachInfo: function (callback) {
      var self = this;

      _.each(this.infos, function (info, id) {
        callback(info);
      });
    },

    update: function (time) {
      var self = this;

      this.forEachInfo(function (info) {
        info.update(time);
      });

      _.each(this.destroyQueue, function (id) {
        delete self.infos[id];
      });
      this.destroyQueue = [];
    }
  });


  var damageInfoColors = {
    "received": {
      fill: "rgb(255, 50, 50)",
      stroke: "rgb(255, 180, 180)",
      direction: Types.Orientations.LEFT
    },
    "inflicted": {
      fill: "white",
      stroke: "#373737",
      direction: Types.Orientations.CENTER
    },
    "healed": {
      fill: "rgb(80, 255, 80)",
      stroke: "rgb(50, 120, 50)",
      direction: Types.Orientations.RIGHT
    },
    "xp": {
      fill: "rgba(210, 216, 57, 0.94)",
      stroke: "rgb(50, 120, 50)",
      direction: Types.Orientations.RIGHT
    }
  };


  var DamageInfo = Class.extend({
    DURATION: 1000,

    init: function (id, value, x, y, duration, type) {
      this.id = id;
      this.value = value;
      this.duration = duration;
      this.x = x;
      this.y = y;
      this.opacity = 1.0;
      this.lastTime = 0;
      this.speed = 100;
      this.fillColor = damageInfoColors[type].fill;
      this.strokeColor = damageInfoColors[type].stroke;
      this.direction = damageInfoColors[type].direction;
    },

    isTimeToAnimate: function (time) {
      return (time - this.lastTime) > this.speed;
    },

    update: function (time) {
      if (this.isTimeToAnimate(time)) {
        this.lastTime = time;
        this.tick();
      }
    },

    tick: function () {
      this.y -= 1;
      switch (this.direction) {
      case Types.Orientations.LEFT:
        this.x -= 1;
        break;
      case Types.Orientations.RIGHT:
        this.x += 1;
        break;
      }
      this.opacity -= 0.07;
      if (this.opacity < 0) {
        this.destroy();
      }
    },

    onDestroy: function (callback)  {
      this.destroy_callback = callback;
    },

    destroy: function () {
      if (this.destroy_callback) {
        this.destroy_callback(this.id);
      }
    }
  });

  return InfoManager;
});
