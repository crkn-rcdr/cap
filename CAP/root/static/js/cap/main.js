define([
    "./expander",
    "./pageViewer",
    "dojo/query",
    "dojo/dom",
    "dojo/parser",
    "dojo/dom-construct",
    "dojo/dom-class",
    "dojo/ready",
    "./requires",
    "./messages",
    "./collectionList",
    "dojo/NodeList-dom",
    "dojo/uacss",
    "dijit/hccss",
    "dojo/domReady!"
], function(expander, pageViewer, $, dom, parser, domConstruct, domClass, ready) {
    // create searchbox expander
    expander(dom.byId("search_box"), ".expand", "#advanced_search");

    // create search result expanders, if necessary
    $(".searchItem.expandable").forEach(function(node, index, array) {
        expander(node, ".expand", ".docRecordDiv");
    });

    // what's this? I can use an expander in the user/subscribe form?
    ready(function() { // Using ready here because the widget has to be created for this to work
        var receipt_section = dom.byId("tax_receipt");
        if (receipt_section) expander(receipt_section, "#wants_tax_receipt", "#tax_fields", dom.byId("wants_tax_receipt").checked);
    });

    // create page viewer, if necessary
    var pvt = dom.byId("pvToolbar");
    if (pvt) {
        $("a", pvt).removeAttr("href");
        console.pv = pageViewer(pvt);
    }

    // throw in some agriculture banners if necessary
    if (domClass.contains(dom.byId("html"), "agriculture")) {
        var fp = $("#main.frontpage").pop();
        if (fp) {
            domConstruct.create("img", { 'class': "left", src: "/static/images/agcan_cover_en.jpg" }, fp);
            domConstruct.create("img", { 'class': "right", src: "/static/images/agcan_cover_fr.jpg" }, fp);
        }
    }

    // hey we're on ECO, better get the descriptions to work
    $('#ecoMoreLink').removeClass('hidden')
        .removeAttr('href')
        .on('click', function(ev) {
            $('#ecoMoreLink').addClass('hidden');
            $('#ecoMore').removeClass('hide_from_js');
        });

    // run the parser!
    parser.parse();
});
