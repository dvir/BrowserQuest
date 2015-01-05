library chatlog;

import "dart:html";
import "dart:math";

import "base.dart";
import "chatmessage.dart";

class ChatLog extends Base {

  static const int DISPLAY_AMOUNT = 5;

  int size;
  List<ChatMessage> _messages = [];

  ChatLog([int this.size = ChatLog.DISPLAY_AMOUNT]);

  void push(ChatMessage message) {
    this._messages.add(message);
  }

  List<ChatMessage> getMessages() {
    return []..addAll(
      this._messages.getRange(
        max(0, this._messages.length - this.size), 
        this._messages.length
      )
    );
  }
}
