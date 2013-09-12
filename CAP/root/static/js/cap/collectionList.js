define([
    "dojo/query",
    "dojo/_base/fx",
    "dojo/on",
    "dojo/dom",
    "dojo/dom-attr",
    "dojo/dom-class",
    "dojo/dom-style",
    "dojo/NodeList-dom",
    "dojo/domReady!"
], function($, fx, on, dom, domAttr, domClass, domStyle) {
    var collectionList = $("ul.collection_list");
    $("ul.collection_list li").forEach(function(node, index, array) {
        var key = domAttr.get(node, "data-collection");
        var target = dom.byId(key);
        domStyle.set(node, { cursor: "pointer" });
        fx.fadeOut({ node: target }).play();
        $("a", node).removeAttr("href");

        on(node, "click", function(ev) {
            collectionList.fadeOut({
                onEnd: function(node) {
                    collectionList.addClass("hidden");
                    domClass.remove(target, "hidden");
                    fx.fadeIn({ node: target }).play();
                }
            }).play();
        });

        var back = $(".back", target);
        back.style({ cursor: "pointer" });
        back.on("click", function(ev) {
            fx.fadeOut({
                node: target,
                onEnd: function(target) {
                    domClass.add(target, "hidden");
                    collectionList.removeClass("hidden");
                    collectionList.fadeIn().play();
                }
            }).play();
        });
    });
});
