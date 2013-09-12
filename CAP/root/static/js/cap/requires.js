define([
    "dojo/query",
    "dojo/dom-construct",
    "dijit/form/Form",
    "dijit/form/Button",
    "dijit/form/CheckBox",
    "dijit/form/TextBox",
    "dijit/form/SimpleTextarea",
    "dijit/form/Select",
    "dijit/form/DateTextBox",
    "dijit/TitlePane",
    "dijit/layout/ContentPane",
    "dijit/layout/TabContainer"
], function($, domConstruct) {
    // replace FORMs with their inner DIV, which gets parsed into a dijit/form/Form
    $('div.form').forEach(function(formDiv) {
        domConstruct.place(formDiv, formDiv.parentElement, 'replace');
    });
    return 1;
});
