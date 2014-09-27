library bubble;

import "dart:html";

import "animationtimer.dart";
import "base.dart";
import "entity.dart";

class Bubble extends Base {

  Entity entity;
  Element container;
  Element element;
  String _message;
  int duration = 2000;
  AnimationTimer timer;

  Bubble(Entity this.entity, Element this.container, String this._message) {
    this.element = new Element.html('<div id="${this.entity.id}" class="bubble"><p>${message}</p><div class="thingy"></div></div>');
    this.container.children.add(this.element);
    this.on("MessageChanged", () {
      this.element.children[0].setInnerHtml(this.message);
    });
    this.reset();
  }

  String get message => this._message;
  void set message(String message) { 
    this._message = message; 
    this.trigger("MessageChanged");
  }

  void update(int time) {
    this.timer.update(time);
  }

  void reset() {
    this.timer = new AnimationTimer(new Duration(milliseconds: this.duration));
    this.timer.on("Over", () {
      this.destroy();
    });
  }

  void destroy() {
    this.element.remove();
    this.trigger("Destroy");
  }
}
