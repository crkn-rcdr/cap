/* pageview.js
 *
 * Version: 1.081118
 * 
 * Javascript functions for the ECO 3 page viewer application/
 *
 * Requires jquery
 *
 * */

pageview = function() {
    this.ui            = new Object(); // User interface elements
    this.cached        = new Object();   // List of pages already loaded
    this.controlState  = new Object();   // Save the enabled/disabled state of all controls

    this.markedPage    = 0;            // Last manually marked page

    this.loadimg        = new Image;
    this.loadimg.owner  = this;
    this.loadimg.onload = setPageImage;
    this.loadWait       = 0;

}
pageview.prototype = {
    
    /*
     * Event Handlers
     * */

    // Mark the selected page for later recall.
    markPage: function(page) {
        this.markedPage = page;
        this.setLabel(this.ui.MarkedPageLabel, this.ui.SelectPage[page-1].text);
        this.updateInterface();
    },

    // Update the doc cookie to the latest page co-ordinates.
    setDocCookie: function() {
        document.cookie = "doc=" + this.cihm + ":" + this.page + ":" + this.markedPage + "; path=/";
    },

    // Display the selected page.
    setPage: function(page) {
        if (isNaN(page) || page < 1 || page > this.pagecount)
            return false; // Ignore out of range requests.
        
        this.page = page;
        this.setDocCookie();
        var url = this.pimg + '/' + this.page + '/' + this.size + '/' + this.rotation
        this.cached[url] = true;
        this.disableInterface();
        this.loadimg.src = url;
        this.preloadPage(this.page + 1);
        this.preloadPage(this.page + 2);
        this.preloadPage(this.page + 3);
        this.preloadPage(this.page - 1);
        return true;
    },

    // Change the page orientation and update the page image.
    setRotation: function(rot) {
        rot = rot % 4;
        this.rotation = rot;
        this.setPage(this.page);
    },

    // Change the page size (width in pixels) and update the page image.
    setSize: function(size) {
        if (size < this.sizeMin)
            size = this.sizeMin;
        else if (size > this.sizeMax)
            size = this.sizeMax;
        this.size = size;
        this.setPage(this.page);
    },

    // Mark the current page and load the previously marked page.
    swapPage: function() {
        var markedPage = this.markedPage;
        this.markPage(this.page);
        this.setPage(markedPage);
        this.setDocCookie();
    },

    /*
     * Other Functions
     * */

    // Request page so that it gets created on the server (if needed) and
    // stored locally for quick retrieval,
    preloadPage: function(page) {
        if (page < 1 || page > this.pagecount)
            return; // Ignore out of range requests.

        var url = this.pimg + '/' + page + '/' + this.size + '/' + this.rotation

        if (this.cached[url])
            return; // Don't preload if we've already done so

        this.cached[url] = true;
        var image = new Image;
        image.src = url;
    },

    // Disable all user interface elements.
    disableInterface: function() {
        this.loadWait = setTimeout("loadWait()", 500);
        for (var widget in this.ui) {
            this.controlState[widget] = this.ui[widget].disabled;
            this.ui[widget].disabled  = true;
        }
    },

    // Enable all user interface elements that were disabled from a call
    // to disableInterface();
    enableInterface: function() {
        for (var widget in this.ui) {
            this.ui[widget].disabled = this.controlState[widget];
        }
        cancelLoadWait(this.loadWait);
    },

    // Change the content of element to text.
    setLabel: function(element, text) {
        var children = element.childNodes;
        for (var i = 0; i < children.length; ++i) {
            element.removeChild(children.item(i));
        }    
        element.appendChild(document.createTextNode(text));
    },


    // Update the interface to reflect the current state of the application.
    updateInterface: function() {
        // Update the page select menu.
        this.ui.SelectPage.selectedIndex = this.page - 1;

        // Update the matching pages menu: if this page is a matching
        // page, select it. Otherwise, use the default.
        if (this.ui.SelectPageMatch.length) {
            this.ui.SelectPageMatch.selectedIndex = 0;
            for (i = 0; i < this.ui.SelectPageMatch.length; ++i) {
                if (this.ui.SelectPageMatch[i].value == this.page)
                    this.ui.SelectPageMatch.selectedIndex = i;
            }
        }

        this.ui.PdfPage.href = this.pimgPdf + '-' + this.page + '.pdf';
        this.ui.PdfChunk.href = this.pimgPdf + '-' + this.page + '-.pdf';

        // If we are looking at the last page, disable the "next page" title
        // for the page image. Otherwise, enable it.
        if (this.page == this.pagecount)
            this.ui.PageImage.title = null;
        else
            this.ui.PageImage.title = this.nextPageText;

        // Hide navigation controls that would lead back to the current
        // page or out of range, and display all others.
        if (this.page == 1) {
            this.ui.PrevPage.style.visibility   = 'hidden';
        }
        else {
            this.ui.PrevPage.style.visibility   = 'visible';
            this.setLabel(this.ui.PrevPageLabel, this.ui.SelectPage[this.page-2].text);
        }

        // Hide page size controls if the current page size is already the
        // minimum or maximum allowed.
        if (this.size <= this.sizeMin) {
            this.ui.Smaller.style.visibility = 'hidden';
        }
        else {
            this.ui.Smaller.style.visibility = 'visible';
        }

        if (this.size >= this.sizeMax) {
            this.ui.Larger.style.visibility = 'hidden';
        }
        else {
            this.ui.Larger.style.visibility = 'visible';
        }

        if (this.page == this.pagecount) {
            this.ui.NextPage.style.visibility   = 'hidden';
        }
        else if (this.ui.SelectPage.length) {
            this.ui.NextPage.style.visibility   = 'visible';
            // We need to make sure the SelectPage object exists and is
            // populated in the condition above to prevent this line from
            // executing and raising an error if it doesn't.
            this.setLabel(this.ui.NextPageLabel, this.ui.SelectPage[this.page].text);
        }

        if (this.markedPage == 0)         this.ui.RecallPage.style.visibility = 'hidden';
        else                              this.ui.RecallPage.style.visibility = 'visible';

        cancelLoadWait(this.loadWait);
    },

}

/*
 * Callback Functions
 */

// Display a loaded page image and update the interface.
function setPageImage() {
    app = this.owner;
    app.ui.PageImage.src          = this.src;
    app.updateInterface();
    app.enableInterface();
}

// loadWait() is called in response to a timeout and displays a
// "loading..." message. cancelLoadWait() hides the message and clears any
// pending timeout.
function loadWait() {
    waitMsg = document.getElementById('uiWaitMsg');
    if (waitMsg)
        waitMsg.style.visibility = 'visible';
}
function cancelLoadWait(timeout) {
    clearTimeout(timeout);
    waitMsg = document.getElementById('uiWaitMsg');
    if (waitMsg)
        waitMsg.style.visibility = 'hidden';
}

function main(cihm, page, mark, pagecount, pimg, pimgPdf, size, rotation, sizeMin, sizeMax) {
    // Create a new page viewing application instance.
    app = new pageview();

    app.cihm      = cihm;       // CIHM number of this document
    app.page      = page;       // sequence of the page currently on display
    app.markedPage = mark;      // currently marked page
    app.pagecount = pagecount;  // total number of page images in the document
    app.pimg      = pimg;       // path to pimg (including the format type and cihm number)
    app.pimgPdf   = pimgPdf;    // as above, but to generate PDF images
    app.size      = size;       // current image size
    app.rotation  = rotation;   // current image rotation (in quarter turns counterclockwise)
    app.sizeMin   = sizeMin;    // minimum allowable image size (width in pixels)
    app.sizeMax   = sizeMax;    // maximum allowable image size (width in pixels)

    // User interface elements. Label "Foo" here corresponds to an HTML
    // element with an id of "uiFoo".
    uiElement = Array(
        'MarkPage',
        'MarkedPageLabel',
        'NextPage',
        'NextPageLabel',
        'PageImage',
        'PdfPage',
        'PdfChunk',
        'PrevPage',
        'PrevPageLabel',
        'RecallPage',
        'Larger',
        'RotLeft',
        'RotRight',
        'SelectPage',
        'SelectPageMatch',
        'Smaller'
    );

    // Register all user interface elements. If there are any missing
    // elements in the HTML source, create corresponding dummy elements.
    for (var ui in uiElement) {
        uiName = uiElement[ui];
        htmlId = 'ui' + uiName;
        element = document.getElementById(htmlId);
        if (element)
            app.ui[uiName] = element;
        else
            app.ui[uiName] = document.createElement('nil');
    }

    // Set event handlers.
    $("#uiLarger").bind    ("click",  function(event){ if (! this.disabled) app.setSize(app.size + 200);       return false });
    $("#uiMarkPage").bind  ("click",  function(event){ if (! this.disabled) app.markPage(app.page);            return false });
    $("#uiNextPage").bind  ("click",  function(event){ if (! this.disabled) app.setPage(app.page + 1);         return false });
    $("#uiPageImage").bind ("click",  function(event){ if (! this.disabled) app.setPage(app.page + 1);         return false });
    $("#uiPrevPage").bind  ("click",  function(event){ if (! this.disabled) app.setPage(app.page - 1);         return false });
    $("#uiRecallPage").bind("click",  function(event){ if (! this.disabled) app.swapPage();                    return false });
    $("#uiRotLeft").bind   ("click",  function(event){ if (! this.disabled) app.setRotation(app.rotation + 1); return false });
    $("#uiRotRight").bind  ("click",  function(event){ if (! this.disabled) app.setRotation(app.rotation + 3); return false });
    $("#uiSelectPage").bind     ("change", function(event){ if (! this.disabled) app.setPage(app.ui.SelectPage.selectedIndex + 1); return false });
    $("#uiSelectPageMatch").bind("change", function(event){ if (! this.disabled) app.setPage(parseInt(app.ui.SelectPageMatch[app.ui.SelectPageMatch.selectedIndex].value)); return false });
    $("#uiSmaller").bind        ("click",  function(event){ if (! this.disabled) app.setSize(app.size - 200);       return false });

    // Save the "next page" text so that we can hide and display it as
    // required.
    app.nextPageText = app.ui.PageImage.title;

    // Set the marked page, if required.
    if (app.markedPage) app.markPage(app.markedPage);

    // Initialize the interface and preload the next and previous pages in
    // the sequence.
    app.updateInterface();
    app.preloadPage(page + 1);
    app.preloadPage(page - 1);
}

