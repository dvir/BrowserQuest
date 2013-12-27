
/* Simple JavaScript Inheritance
 * By John Resig http://ejohn.org/
 * MIT Licensed.
 */
// Inspired by base2 and Prototype
var initializing = false, fnTest = /xyz/.test(function(){xyz;}) ? /\b_super\b/ : /.*/;
    
// The base Class implementation (does nothing)
Class = function() {};

Class.prototype = {
};

// Create a new Class that inherits from this class
Class.extend = function(prop) {
    var _super = this.prototype;
    
    // Instantiate a base class (but only create the instance,
    // don't run the init constructor)
    initializing = true;
    var prototype = new this();
    initializing = false;

    // Copy the properties over onto the new prototype
    for (var name in prop) {
        // data property should be extended, not copied
        if (name == "data") {
            $.extend(prototype.data, prop.data);
            continue;
        }

        // check if the property is a getter or a setter
        // and if so handle it differently
        var g = prop.__lookupGetter__(name), s = prop.__lookupSetter__(name);
        if (g || s) {
            if (g)
                prototype.__defineGetter__(name, g);
            if (s)
                prototype.__defineSetter__(name, s);

            continue;
        }

        // Check if we're overwriting an existing function
        prototype[name] = typeof prop[name] == "function" &&
            typeof _super[name] == "function" && fnTest.test(prop[name]) ?
            (function(name, fn){
                return function() {
                    var tmp = this._super;
                   
                    // Add a new ._super() method that is the same method
                    // but on the super-class
                    this._super = _super[name];
                   
                    // The method only need to be bound temporarily, so we
                    // remove it when we're done executing
                    var ret = fn.apply(this, arguments);
                    this._super = tmp;
                   
                    return ret;
                };
            })(name, prop[name]) :
            prop[name];
    }
   
    // The dummy class constructor
    Class = function () {
        // All construction is actually done in the init method
        if (!initializing) {
            if (!this.bubbleToObjects) this.bubbleToObjects = [];
            if (!this.callbacks) this.callbacks = {};

            this.on = function(names, callback) {
                if (!(names instanceof Object)) {
                  names = [names];
                }

                for (var x in names) {
                  var name = names[x];

                  if (!this.callbacks.hasOwnProperty(name)) {
                      this.callbacks[name] = [];
                  }
                  this.callbacks[name].push(callback);
                }
            };
            
            this.trigger = function(name) {
                if (this.callbacks.hasOwnProperty(name)) {
                    for (var i = 0; i < this.callbacks[name].length; i++) {
                        this.callbacks[name][i].apply(this, Array.prototype.slice.call(arguments, 1));
                    }
                }

                for (var i = 0; i < this.bubbleToObjects.length; i++) {
                    this.bubbleToObjects[i].trigger(name);
                }
            };

            this.bubbleTo = function(object) {
                this.bubbleToObjects.push(object);
            };

            if (this.data) {
                this.data = $.extend({}, prototype.data, this.data);
            }
            if (this.callbacks) {
                this.callbacks = $.extend({}, prototype.callbacks, this.callbacks);
            }
            if (this.init) {
                this.init.apply(this, arguments);
            }
        }
    }
    
    // Populate our constructed prototype object
    Class.prototype = prototype;
    
    // Enforce the constructor to be what we expect
    Class.constructor = Class;
    
    // And make this class extendable
    Class.extend = arguments.callee;

    return Class;
};

if(!(typeof exports === 'undefined')) {
    exports.Class = Class;
}

