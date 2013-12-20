
define(['chatlog'], function(ChatLog) {

    var Chat = Class.extend({ 
        init: function(data) {
            this.log = new ChatLog(5);
            this.channel = "say";
        },

        push: function(message) {
            this.log.push(message);
        },

        setChannel: function(channel) {
            this.channel = channel;
        },

        getChannel: function() {
            return this.channel;
        },

        getMessages: function() {
            return this.log.toArray();
        }
    });

    return Chat;
});

