
define(['chatlog', 'chatmessage'], function(ChatLog, ChatMessage) {

    var Chat = Class.extend({ 
        init: function() {
            // @TODO: move to a proper config
            var log_size = 5;
            var default_channel = "say";

            this._log = new ChatLog(log_size);
            this._channel = default_channel;
            this._input = null;

            this._updateInputPlaceholder();
        },

        setInput: function(input) {
            this._input = input;
            this._updateInputPlaceholder();
        },
    
        _updateInputPlaceholder: function() {
            if (!this._input) {
                return;
            }

            this._input.attr("placeholder", this.getChannel());
        },

        insertMessage: function(
           entity, 
           name, 
           message, 
           channel
        ) {
            var message = new ChatMessage(
                entity, 
                name, 
                message, 
                channel
            );

            this._log.push(message);
        },

        insertError: function(message) {
            this.insertMessage(
                /* entity */ null, 
                /* name */ null, 
                message, 
                "error"
            );
        },

        insertNotice: function(message) {
            this.insertMessage(
                /* entity */ null, 
                /* name */ null, 
                message, 
                "notice"
            );
        },

        setChannel: function(channel) {
            this._channel = channel;
            this._updateInputPlaceholder();
        },

        getChannel: function() {
            return this._channel;
        },

        getMessages: function() {
            return this._log.toArray();
        }
    });

    return Chat;
});
