define([], function () {

  /**
   * A chat message representation allowing us to validate the data
   * and logic specific to each chat message.
   */
  var ChatMessage = Class.extend({
    /**
     * Most of the times, the name parameter can be derived from the
     * entity, but in case the player has logged off / mob died / etc.
     * we need to cache that name and use it for display.
     * In general, entity is not safe after init().
     */
    init: function (entity, name, text, channel) {
      this._name = name;
      this._text = text;
      this._channel = channel;
      this._time = new Date().getTime();
    },

    getTime: function () {
      return this._time;
    },

    getTimestamp: function () {
      var date = new Date(this.getTime());
      var time = ("0" + date.getHours()).slice(-2) + ":" + ("0" + date.getMinutes()).slice(-2);
      return time;
    },

    getName: function () {
      return this._name;
    },

    getText: function () {
      return this._text;
    },

    getChannel: function () {
      return this._channel;
    }
  });

  return ChatMessage;
});
