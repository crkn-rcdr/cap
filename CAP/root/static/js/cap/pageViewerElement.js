define(["dojo/dom", "dojo/dom-class"], function(dom, domClass) {
    return function(nodeName) {
        var node = dom.byId(nodeName);
        var that = {};

        that.getNode = function() { return node; };
        that.hide = function() { domClass.add(node, "hidden"); };
        that.show = function() { domClass.remove(node, "hidden"); };

        return that;
    };
});
