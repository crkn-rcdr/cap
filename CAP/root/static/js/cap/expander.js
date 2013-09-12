define(["dojo/query", "dojo/dom-class", "dojo/NodeList-fx", "dojo/domReady!"], function($, domClass) { 
    return function(containerNode, expanderQuery, targetQuery, initialState) {
        var expanded = initialState || false;
        var expander = $(expanderQuery, containerNode);
        var target = $(targetQuery, containerNode);
        expander.removeAttr("href");
        expander.removeClass("max");
        expander.addClass("min");

        var show = function() {
            target.wipeIn().play();
            expander.removeClass("min");
            expander.addClass("max");
            expanded = true;
        };

        var hide = function() {
            target.wipeOut().play();
            expander.removeClass("max");
            expander.addClass("min");
            expanded = false;
        };

        // this is referring to how it should look initially, which is why it's different from the onclick
        expanded ? show() : hide();
        target.removeClass("hidden");

        expander.on("click", function(ev) { expanded ? hide() : show(); });
    };
});
