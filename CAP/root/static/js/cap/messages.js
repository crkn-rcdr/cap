define(["dojo/query", "dojo/_base/fx", "dojo/dom-class", "dojo/domReady!"], function($, fx, domClass) {
    $('ul.messages li div.close').removeClass("hidden");
    $('ul.messages li').forEach(function(node, index, array) {
        $('.close', node).on("click", function(ev) {
            fx.fadeOut({
                node: node,
                onEnd: function(node) {
                    domClass.add(node, "hidden");
                }
            }).play();
        });
    });
});
