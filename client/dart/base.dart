import 'dart:math';

class EventHandler {
  String _handler;

  EventHandler() {
    this._handler = this._handlerGenerator();
  }

  String _handlerGenerator() {
    Random rng = new Random();
    String S4() => ((1+rng.nextInt(0x10000)) | 0).toRadixString(16).substring(1);
    return (S4()+S4()+"-"+S4()+"-"+S4()+"-"+S4()+"-"+S4()+S4()+S4());
  }
}

class Base {
  Map<String, Map<EventHandler, Function>> callbacks = new Map<String, Map<EventHandler, Function>>();
  List<Base> bubbleTargets = new List<Base>();

  Map<String, EventHandler> on(var names, Function callback, [bool overwritePrevious = false]) {
    if (!(names is List)) {
      names = [names];
    }

    Map<String, EventHandler> handlers = new Map<String, EventHandler>();

    names.forEach((String name) {
      EventHandler eh = new EventHandler();
      if (overwritePrevious && callbacks.containsKey(name)) {
        callbacks.remove(name); 
      }
      callbacks.putIfAbsent(name, () => new Map<EventHandler, Function>());
      callbacks[name].putIfAbsent(eh, () => callback);
      handlers.putIfAbsent(name, () => eh);
    });

    return handlers;
  }

  void off(Map<String, EventHandler> handlers) {
    handlers.forEach((String name, EventHandler eh) => this.callbacks[name].remove(eh));
  }

  void trigger(var names, [List args]) {
    if (!(names is List)) {
      names = [names];
    }

    this.callbacks.forEach((String name, Map<EventHandler, Function> ehs) {
      ehs.forEach((EventHandler handler, Function callback) {
        Function.apply(callback, args);
      });

      this.bubbleTargets.forEach((Base object) => object.trigger(name, args));
    });
  }

  void bubbleTo(Base object) {
    this.bubbleTargets.add(object);
  }
}
