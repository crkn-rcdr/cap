define([
    "dojo/_base/window",
    "dojo/_base/array",
    "dojo/dom-construct"
], function(win, array, construct) {
    var that = {};
    var cacheNode;

    that.preload = function(uris) {
        if (!cacheNode) {
            cacheNode = construct.create("div", {
                style: {
                    position: "absolute",
                    'top': "-9999px",
                    height: "1px",
                    overflow: "hidden"
                }
            }, win.body());
        }

        return array.map(uris, function(uri) {
            return construct.create("img", { src: uri }, cacheNode);
        });
    };

    return that;
});
