// Enable debugging to provide alerts when various transactions would
// otherwise silently fail.
var Debug = false;
var Interactive = false;

function debug(message) {
    if (Debug) {
        $("#Debug").append(message + "\n");
    }
}

$(document).ready(function() {
    debug("Debug mode enabled");
});
