library chat;

import "dart:html";

import "base.dart";
import "chatlog.dart";
import "chatmessage.dart";
import "entity.dart";

class Chat extends Base {

  static final String DEFAULT_CHANNEL = "say";

  ChatLog _log = new ChatLog();
  String _channel = Chat.DEFAULT_CHANNEL;
  InputElement _input;

  Chat([InputElement input = null]) {
    this.input = input;
  }

  InputElement get input => this._input;
  void set input(InputElement input) {
    this._input = input;
    this._updateInputPlaceholder();
  }

  String get channel => this._channel;
  void set channel(String channel) {
    this._channel = channel;
    this._updateInputPlaceholder();
  }

  void _updateInputPlaceholder() {
    if (this.input == null) {
      return;
    }

    this._input.setAttribute("placeholder", this.channel);
  }

  void insertMessage(String message, String channel, [Entity entity = null, String prefix = ""]) {
    this._log.push(new ChatMessage(message, channel, entity, prefix));
  }

  void insertError(String message) {
    this.insertMessage(message, "error");
  }

  void insertNotice(String message) {
    this.insertMessage(message, "notice");
  }

  List<ChatMessage> getMessages() => this._log.getMessages(); 
}
