i18n = {

// Open the translation editor dialog and populate it with the ID and
// content of the message to be edited.
editOpen: function(event)
{
    var id = event.target.id;
    this.edit_id = id;

    // Get the IDs of the relevant elements.
    var msgid =   "#" + id + "_msgid";
    var message = "#" + id + "_message";
    var value = "#" + id + "_value";
    var notes =   "#" + id + "_notes";

    // Copy their contents into the edit fields.
    $("#i18n_edit_msgid").val($(msgid).text());
    $("#i18n_edit_message").text($(message).text());
    $("#i18n_edit_value").val($(value).text());
    $("#i18n_edit_notes").text($(notes).text());

    // Move the edit dialog to about the height of the current mouse
    // pointer and make it visible.
    $("#i18n_edit").css("top", event.pageY - 100);
    $("#i18n_edit").css("visibility", "visible");

},

// Hide the edit dialog.
editCancel: function(event)
{
    $("#i18n_edit").css("visibility", "hidden");
},

editSubmit: function(event)
{
    // Verify that the correct number of placeholders have been entered.
    // TODO: this doesn't prevent too many from being added
    // TODO: do we really want to do this then?
    var txt_orig = $("#i18n_edit_message").text();
    var txt_trans = $("#i18n_edit_value").val();
    var placeholder = /\[_[0-9]+\]/g;
    var match;
    // FIXME: this only works on the first go-round; probaby because a
    // pointer is saved and subsequent tries are already ast the ene?
    while ((match = placeholder.exec(txt_orig)) != null) {
        if (txt_trans.indexOf(match) < 0) {
            alert("Missing placeholder: " + match);
            placeholder = null;
            return false;
        }
    }

    $("#i18n_edit_wait").css("visibility", "visible");

    $.post(
        this.uri,
        {
            iface: "json",
            update : 1,
            id : $("#i18n_edit_msgid").val(),
            value : $("#i18n_edit_value").val()
        },
        function(json) {
            //alert("DONE");
            var value = "#" + i18n.edit_id + "_value";
            $(value).text($("#i18n_edit_value").val());
            $("#i18n_edit_wait").css("visibility", "hidden");
            $("#i18n_edit").css("visibility", "hidden");
        },
        "json"
    );

    //return true;
    return false;
}


}; // End i18n


// Initialize the application as soon as the document is ready.
$(document).ready(function()
{
    i18n.uri = uri;
    // Bind event handlers to various UI elements.
    $(".i18n_do_edit").bind("click", function(event) { i18n.editOpen(event); });
    $("#i18n_edit_cancel").bind("click", function(event) { i18n.editCancel(event); });

    $("#i18n_edit_form").submit(function(event) { return i18n.editSubmit(event); });
});
