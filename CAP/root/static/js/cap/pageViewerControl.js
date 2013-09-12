define(["dojo/on", "dojo/dom", "dojo/dom-class", "dojo/_base/lang"], function(on, dom, domClass, lang) {
    return function(spec) {
        var node = dom.byId(spec.nodeName);
        var eventName = spec.eventName;
        var handler = spec.handler;
        var pv = spec.pv;
        var handle = on.pausable(node, eventName, lang.hitch(pv, handler));
        handle.pause(); // Start disabled
        var that = {};

        that.getNode = function() { return node; };
        that.enable = function() {
            handle.resume();
            domClass.remove(node, "disabled selected hidden");
        };
        that.disable = function(className) {
            handle.pause();
            domClass.add(node, className);
        };

        return that;
    };
});

