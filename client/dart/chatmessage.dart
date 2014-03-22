library chatmessage;

import "base.dart";
import "entity.dart";

/**
 * A chat message representation allowing us to validate the data
 * and logic specific to each chat message.
 */
class ChatMessage extends Base {

  /**
   * Most of the times, the name parameter can be derived from the
   * entity, but in case the player has logged off / mob died / etc.
   * we need to cache that name and use it for display.
   * In general, entity is not safe after init().
   */
  String name;
  String text;
  String channel;
  DateTime time;

  ChatMessage(String this.text, String this.channel, [Entity entity = null, String prefix = ""]) {
    if (entity != null) {
      this.name = prefix + entity.name;
    }

    this.time = new DateTime.now();
  }

  String getTimestamp() {
    String hours = "0${this.time.hour}";
    String minutes = "0${this.time.minute}";
    return "${hours.substring(hours.length-2)}:${minutes.substring(minutes.length-2)}";
  }
}
