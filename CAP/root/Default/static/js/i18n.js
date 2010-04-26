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
    $("#i18n_edit_notes").val($(notes).text());

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
    $("#i18n_edit_wait").css("visibility", "visible");

    $.post(
        this.uri,
        {
            iface: "json",
            action : "update",
            id : $("#i18n_edit_msgid").val(),
            value : $("#i18n_edit_value").val(),
            notes : $("#i18n_edit_notes").val()
        },
        function(json) {
            var value = "#" + i18n.edit_id + "_value";
            var notes = "#" + i18n.edit_id + "_notes";
            $(value).text($("#i18n_edit_value").val());
            $(notes).text($("#i18n_edit_notes").val());
            $("#i18n_edit_wait").css("visibility", "hidden");
            $("#i18n_edit").css("visibility", "hidden");
        },
        "json"
    );

    //return true;
    return false;
},

editDelete: function()
{
    var id = $("#i18n_edit_msgid").val();
    if(confirm("Are you sure you want to delete message ID " + id)) {
        $.post(
            this.uri,
            {
                iface: "json",
                action: "delete",
                id: id,
            },
            function(json) {
                $("#i18n_" + id).parent().parent().remove();
                $("#i18n_edit_wait").css("visibility", "hidden");
                $("#i18n_edit").css("visibility", "hidden");
            },
            "json"
        );
    }
}


}; // End i18n


// Initialize the application as soon as the document is ready.
$(document).ready(function()
{
    i18n.uri = CAP.base_uri;
    // Bind event handlers to various UI elements.
    $(".i18n_do_edit").bind("click", function(event) { i18n.editOpen(event); });
    $("#i18n_edit_cancel").bind("click", function(event) { i18n.editCancel(event); });

    $("#i18n_edit_form").submit(function(event) { return i18n.editSubmit(event); });
    $("#i18n_edit_delete").click(function() { i18n.editDelete() });
});
