library bubblemanager;

import "dart:html";

import "base.dart";
import "bubble.dart";
import 'entity.dart';

class BubbleManager extends Base {

  Element container;
  Map<int, Bubble> bubbles = new Map<int, Bubble>();

  BubbleManager(Element this.container);

  Bubble getBubbleByID(int id) {
    return this.bubbles[id];
  }

  void create(Entity entity, String message) {
    if (this.bubbles.containsKey(entity.id)) {
      this.bubbles[entity.id].message = message;
      this.bubbles[entity.id].reset();
      return;
    }

    Bubble bubble = new Bubble(entity, this.container, message);
    this.bubbles[entity.id] = bubble;
    bubble.on("Destroy", () {
      this.bubbles.remove(entity.id);
    });
  }

  void destroy(int id) {
    if (this.bubbles.containsKey(id)) {
      this.bubbles[id].destroy();
    }
  }

  void clean() {
    Map<int, Bubble> bubbles = new Map<int, Bubble>.from(this.bubbles);
    bubbles.forEach((int id, Bubble bubble) {
      bubble.destroy();
    });
  }

  void update(int time) {
    Map<int, Bubble> bubbles = new Map<int, Bubble>.from(this.bubbles);
    bubbles.forEach((int id, Bubble bubble) {
      bubble.update(time);
    });
  }
}
