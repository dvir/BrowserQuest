
define([], function() {

    /**
     * A chat log queue of messages accessible with .push and .toArray.
     */
    var ChatLog = Class.extend({ 
        init: function(max_lines) {
            this.max_lines = max_lines;
            this.messages = new Array(this.max_lines);
            this.index = 0;
        },

        setMaxLines: function(max_lines) {
            var arr = this.toArray();
            var toCopy = this.arr.slice(arr.length - max_lines, arr.length);
            this.messages = new Array(max_lines);
            this.max_lines = max_lines;

            for (var i in toCopy) {
                this.push(toCopy[i]);
            }
        },

        push: function(message) {
            message.time = new Date().getTime();
            this.messages[this.index] = message;
            this.index = (this.index + 1) % this.max_lines;
        },
    
        toArray: function() {
            var orderedMessages = [];
            for (var i = 0; i < this.max_lines; i++) {
                var message = this.messages[(i + this.index) % this.max_lines];
                if (message) {
                    orderedMessages.push(message);
                }
            }

            return orderedMessages;
        }
    });

    return ChatLog;
});


