viewer = {

setPage: function(index)
{
    if (index >= 0 && index <= this.last_page) {
        $("#ui_page_loading").css("visibility", "visible");
        debug("Setting page to index  " + index + " of " + this.last_page);
        this.setImage(this.imgload_page, index, this.page_size);
        this.setImage(this.imgload_prev, index - 1, this.thumb_size);
        this.setImage(this.imgload_next, index + 1, this.thumb_size);
        this.page = index;
    }
    else {
        debug("Out of range request: " + index + " (last = " + this.last_page + ")");
    }

    return false;
},

cacheImage: function(offset, size)
{
    if (offset >= 0 && offset <= this.last_page) {
        var uri = this.uri + "?key=" + this.pages[offset].key + "&rel=image&s=" + size;
        var img = new Image();
        img.src = uri;
    }
},

setImage: function(loader, index, size)
{
    if (index >= 0 && index <= this.last_page) {
        var uri = this.uri + "?key=" + this.pages[index].key + "&rel=image&s=" + size;
        loader.src = uri;
    }
},

precache: function()
{
    debug("Pre-caching");
    this.cacheImage(this.page, this.page_size);
    this.cacheImage(this.page + 1, this.page_size);
    this.cacheImage(this.page + 2, this.page_size);
    //this.cacheImage(this.page + 3, this.page_size);
    this.cacheImage(this.page - 1, this.page_size);
    this.cacheImage(this.page + 2, this.thumb_size);
    //this.cacheImage(this.page + 3, this.thumb_size);
    //this.cacheImage(this.page + 4, this.thumb_size);
    this.cacheImage(this.page - 2, this.thumb_size);
},

updateInterface: function()
{
    debug("Updating interface. Page: " + this.page);

    // Update the page selector to show the current page.
    this.ui.select_page.selectedIndex = this.page;

    // Previous page navigation button, label, and thumbnail
    if (this.page > 0) {
        $(this.ui.prev_label).text($(this.ui.select_page[this.page - 1]).text());
        $(this.ui.prev).css("visibility", "visible");
    }
    else {
        $(this.ui.prev).css("visibility", "hidden");
    }

    // Next page navigation button, label, and thumbnail
    if (this.page < this.last_page) {
        $(this.ui.next_label).text($(this.ui.select_page[this.page + 1]).text());
        $(this.ui.next).css("visibility", "visible");
    }
    else {
        $(this.ui.next).css("visibility", "hidden");
    }

    this.enabled = true;
}

} // End viewer


$(document).ready(function()
{

    // Get references to all of the UI elements we need to access.
    viewer.ui = new Object();
    viewer.ui.next = document.getElementById("ui_next");
    viewer.ui.next_image = document.getElementById("ui_next_image");
    viewer.ui.next_label = document.getElementById("ui_next_label");
    viewer.ui.page_image = document.getElementById("ui_page_image");
    viewer.ui.prev = document.getElementById("ui_prev");
    viewer.ui.prev_image = document.getElementById("ui_prev_image");
    viewer.ui.prev_label = document.getElementById("ui_prev_label");
    viewer.ui.select_page = document.getElementById("ui_select_page");
    viewer.ui.loading = document.getElementById("ui_page_loading");

    // Set the base URI and the initial widths (in pixels) for the main
    // page image and thumbnails.
    viewer.uri = CAP.base_uri;
    viewer.page_size = 500;
    viewer.thumb_size = 50;

    viewer.imgload_page = new Image();
    viewer.imgload_page.onload = function() {
        viewer.ui.page_image.src = viewer.imgload_page.src;
        viewer.updateInterface();
        $(viewer.ui.loading).css("visibility", "hidden");
        viewer.precache();
    };
    viewer.imgload_next = new Image();
    viewer.imgload_next.onload = function() { viewer.ui.next_image.src = viewer.imgload_next.src; };
    viewer.imgload_prev = new Image();
    viewer.imgload_prev.onload = function() { viewer.ui.prev_image.src = viewer.imgload_prev.src; };

    // Build a page -> label index and determine the index of the current
    // and last pages.
    viewer.pages = new Object();
    if (viewer.ui.select_page) {
        $("#ui_select_page option").each(function(i, select){
            viewer.pages[i] = new Object();
            viewer.pages[i].key = $(select).val(); // we don't actually use this, at least not right now
            viewer.pages[i].label = $(select).text();
            //debug(i + ": " + viewer.pages[i].key + ", " + viewer.pages[i].label);
        });
        viewer.last_page = $(viewer.ui.select_page)[0].length - 1;
        viewer.page = $(viewer.ui.select_page)[0].selectedIndex;
    }


    // Pre-load the next few pages and set up the interface.
    viewer.precache();

    // Load preview thumbnails
    $(".ui_preview_image").each(function(i, img){
        viewer.setImage(img, i, viewer.thumb_size);
    });

    if (Interactive) {
        viewer.updateInterface();

        // Remove elements that aren't needed in the interactive version.
        if (viewer.ui.page_image) {
            $("#ui_select_submit").css("display", "none");
        }
        $("#ui_next").click(function(event){ if (viewer.enabled) { (viewer.setPage(viewer.page + 1)); } return false; });
        $("#ui_prev").click(function(event){ if (viewer.enabled) { viewer.setPage(viewer.page - 1); } return false; });
        $("#ui_select_page").change(function(event) { if (viewer.enabled) { viewer.setPage(($("#ui_select_page")[0].selectedIndex)); } return false; });
    }
});
