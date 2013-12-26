Function.prototype._bind = function (bind) {
  return function () {
    var args = Array.prototype.slice.call(arguments);
    return this.apply(bind || null, args);
  }.bind(this);
};

var isInt = function (n) {
  return (n % 1) === 0;
};

var TRANSITIONEND = 'transitionend webkitTransitionEnd oTransitionEnd';

// http://paulirish.com/2011/requestanimationframe-for-smart-animating/
window.requestAnimFrame = (function () {
  return window.requestAnimationFrame ||
    window.webkitRequestAnimationFrame ||
    window.mozRequestAnimationFrame ||
    window.oRequestAnimationFrame ||
    window.msRequestAnimationFrame ||
    function ( /* function */ callback, /* DOMElement */ element) {
      window.setTimeout(callback, 1000 / 60);
  };
})();
