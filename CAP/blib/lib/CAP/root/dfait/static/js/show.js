viewer = {

cache : Object(),

getPage: function(json)
{
    if (json.ok) {
        debug("JSON request OK: " + json.req);
        if (json.image_uri && json.image_key) {
            this.cache = new Image();
            this.cache.src = json.image_uri;
        }
    }
    else {
        debug("JSON request not OK; status: " + json.status + "; error: " + json.error + "; request: " + json.req);
    }
},

bar: function()
{
    alert("HI");
}

} // End viewer


$(document).ready(function()
{
    //viewer = new Viewer();

    // Determine the base show uri by taking the URI for the document itself
    // and then removing the key from the end.
    // viewer.base_uri = doc.uri.substring(0, (doc.uri.length - doc.key.length));

    // Pre-load the next and previous pages in the sequence.
    next_page_uri = doc.uri + "?rel=next&iface=json";
    debug("JSON request for: " + next_page_uri);
    $.getJSON(next_page_uri, function(json) { viewer.getPage(json); });

    prev_page_uri = doc.uri + "?rel=prev&iface=json";
    debug("JSON request for: " + prev_page_uri);
    $.getJSON(prev_page_uri, function(json) { viewer.getPage(json); });

});
