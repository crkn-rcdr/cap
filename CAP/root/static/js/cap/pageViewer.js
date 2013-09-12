define([
    "./pageViewerElement",
    "./pageViewerControl",
    "./preloader",
    "dojo/query",
    "dojo/dom",
    "dojo/dom-attr",
    "dojo/dom-style",
    "dojo/_base/xhr",
    "dojo/_base/lang",
    "dojo/_base/array",
    "dojo/_base/fx",
    "/static/js/native.history.js"
], function(pve, pvc, preloader, $, dom, domAttr, domStyle, xhr, lang, array, fx) {
    return function(dataNode) {
        // public object to be returned
        var that = {};

        // private variables
        var state = {
            seq: parseInt(domAttr.get(dataNode, "data-seq"), 10),
            r: parseInt(domAttr.get(dataNode, "data-rotation"), 10),
            s: parseInt(domAttr.get(dataNode, "data-size"), 10)
        };
        var pkey = domAttr.get(dataNode, "data-pkey");
        var total = parseInt(domAttr.get(dataNode, "data-total"), 10);
        var minSize = parseInt(domAttr.get(dataNode, "data-min-size"), 10);
        var maxSize = parseInt(domAttr.get(dataNode, "data-max-size"), 10);
        var canResize = !!parseInt(domAttr.get(dataNode, "data-resize"), 10);
        var portalName = domAttr.get(dataNode, "data-portal-name");
        var documentLabel = domAttr.get(dataNode, "data-document-label");
        var currentView = domAttr.get(dataNode, "data-initial-view");

        // image uri cache
        var cache = {};

        // display nodes
        var image = dom.byId("pvImg");
        var display = {
            container: pve("pvImageContainer"),
            toolbar: pve("pvToolbar"),
            loading: pve("pvLoading"),
            error: pve("pvError"),
            subscribe: pve("pvSubscribe")
        };

        // control handlers
        that.firstPage = function() { updateState({ seq: 1 }); };
        that.previousPage = function() { updateState({ seq: state.seq - 1 }); };
        that.nextPage = function() { updateState({ seq: state.seq + 1 }); };
        that.lastPage = function() { updateState({ seq: total }); };
        that.selectPage = function() { updateState({ seq: parseInt(controls.pageSelect.getNode().value, 10) }); };
        that.rotateLeft = function() { updateState({ r: (state.r + 3) % 4 }); };
        that.rotateRight = function() { updateState({ r: (state.r + 1) % 4 }); };
        that.smaller = function() { updateState({ s: state.s - 1 }); };
        that.bigger = function() { updateState({ s: state.s + 1 }); };

        // UI controls
        var controls = {
            first: pvc({ pv: that, nodeName: "pvFirst", eventName: "click", handler: "firstPage" }),
            previous: pvc({ pv: that, nodeName: "pvPrevious", eventName: "click", handler: "previousPage" }),
            previousBar: pvc({ pv: that, nodeName: "pvImgPrev", eventName: "click", handler: "previousPage" }),
            next: pvc({ pv: that, nodeName: "pvNext", eventName: "click", handler: "nextPage" }),
            nextBar: pvc({ pv: that, nodeName: "pvImgNext", eventName: "click", handler: "nextPage" }),
            last: pvc({ pv: that, nodeName: "pvLast", eventName: "click", handler: "lastPage" }),
            pageSelect: pvc({ pv: that, nodeName: "pvPageSelect", eventName: "change", handler: "selectPage" }),
            rotateLeft: pvc({ pv: that, nodeName: "pvRotateLeft", eventName: "click", handler: "rotateLeft" }),
            rotateRight: pvc({ pv: that, nodeName: "pvRotateRight", eventName: "click", handler: "rotateRight" }),
            smaller: pvc({ pv: that, nodeName: "pvSmaller", eventName: "click", handler: "smaller" }),
            bigger: pvc({ pv: that, nodeName: "pvBigger", eventName: "click", handler: "bigger" })
        };

        // utility methods
        var pkeyOutFront = function() {
            return window.location.pathname.split("/").pop() === pkey;
        };
        var makePathFromState = function(st) {
            return "" + (pkeyOutFront() ? pkey + "/" : "") + st.seq + "?r=" + st.r + "&s=" + st.s;
        };
        var hashToState = function(hash) {
            var obj = xhr.queryToObject(hash);
            var st = {};
            array.forEach(['seq', 's', 'r'], function(name) { if (obj[name]) st[name] = parseInt(obj[name], 10); });
            return st;
        };
        var sanitize = function(st) {
            if (st.seq < 1) st.seq = 1;
            if (st.seq > total) st.seq = total;
            if (st.r > 3 || st.r < 0) st.r = 0;
            if (st.s < minSize) st.s = minSize;
            if (st.s > maxSize) st.s = maxSize;
            return st;
        };
        var pageAccess = function(seq) {
            var item = controls.pageSelect.getNode().namedItem("seq" + seq);
            return !!parseInt(domAttr.get(item, "data-access"), 10);
        };
        var cacheRef = function(seq, r, s) {
            return seq + "," + r + "," + s;
        };
        var resizeDisplay = function() {
            domStyle.set(display.container.getNode(), "width", parseInt(image.width, 10) + "px");
        };

        // flow methods
        var initState = function() {
            var hash = History.getHash();
            if (hash) lang.mixin(state, hashToState(hash));
            History.replaceState(sanitize(state), null, currentView === "page" ? makePathFromState(state) : History.getState().url);
        };
        var updateState = function(newState) {
            var st = lang.mixin(state, newState);
            display.loading.show();
            History.pushState(sanitize(st), null, makePathFromState(st));
            return true;
        };
        var updateUI = function() {
            if (state.seq <= 1) {
                controls.first.disable("disabled");
                controls.previous.disable("disabled");
                controls.previousBar.disable("hidden");
            } else {
                controls.first.enable();
                controls.previous.enable();
                controls.previousBar.enable();
            }
            if (state.seq >= total) {
                controls.last.disable("disabled");
                controls.next.disable("disabled");
                controls.nextBar.disable("hidden");
            } else {
                controls.last.enable();
                controls.next.enable();
                controls.nextBar.enable();
            }

            controls.pageSelect.enable();
            controls.pageSelect.getNode().value = state.seq;
            controls.rotateLeft.enable();
            controls.rotateRight.enable();
            (state.s <= minSize || !canResize) ? controls.smaller.disable("disabled") : controls.smaller.enable();
            (state.s >= maxSize || !canResize) ? controls.bigger.disable("disabled") : controls.bigger.enable();

            if (currentView === "page") {
                var pageSelectNode = controls.pageSelect.getNode();
                var itemName = pageSelectNode.namedItem("seq" + state.seq).innerHTML;
                document.title = documentLabel + " - " + itemName + " - " + portalName;
            }
        };
        that.getUri = function(seq) {
            var args = { r: state.r, s: state.s, fmt: 'ajax' };
            var call = '/file/get_page_uri/' + pkey + '/' + seq;
            var ref = cacheRef(seq, state.r, state.s);
            xhr.get({
                url: call,
                content: args,
                handleAs: 'json',
                load: function(data) {
                    if (data["status"] === 200) {
                        cache[ref] = data.uri;
                        preloader.preload([data.uri]);
                    } else {
                        cache[ref] = "error";
                    }
                },
                error: function(error) {
                    setTimeout(lang.hitch(that, "getUri", seq), 1000);
                }
            });
        };
        that.preload = function(seq) {
            array.forEach([seq, seq - 1, seq + 1, seq + 2, seq + 3], function(newSeq) {
                var ref = cacheRef(newSeq, state.r, state.s);
                if (newSeq >= 1 &&
                    newSeq <= total &&
                    pageAccess(newSeq) &&
                    (state.s === minSize || canResize) &&
                    !cache[ref]) {
                    this.getUri(newSeq);
                }
            }, that);
        };
        that.requestImage = function() {
            var uri = cache[cacheRef(state.seq, state.r, state.s)];
            if (uri && uri !== "error") {
                image.src = uri;
                display.subscribe.hide();
                display.error.hide();
                display.container.show();
            } else if (!uri) {
                setTimeout(lang.hitch(that, "requestImage"), 1000);
            }
        };
        that.stateChanged = function() {
            state = sanitize(History.getState().data);
            that.preload(state.seq);
            if (pageAccess(state.seq) && (state.s == minSize || canResize)) {
                that.requestImage();
            } else {
                display.container.hide();
                display.loading.hide();
                display.subscribe.show();
            }
            currentView = "page";
            updateUI();
        };
        that.imageLoaded = function() {
            display.loading.hide();
            display.error.hide();
            display.subscribe.hide();
            resizeDisplay();
        };
        that.imageError = function() {
            display.loading.hide();
            display.container.hide();
            display.subscribe.hide();
            display.error.show();
        };

        // bindings
        History.Adapter.bind(window, 'statechange', that.stateChanged);
        image.onload = lang.hitch(that, "imageLoaded");
        image.onerror = lang.hitch(that, "imageError");

        // Set up mouse events for image nav links
        var imageLinks = $(".pv_image_link");
        imageLinks.style({ opacity: 0 });
        imageLinks.on("mouseover", function(ev) { fx.anim(this, { opacity: 0.5 }); });
        imageLinks.on("mouseout", function(ev) { fx.anim(this, { opacity: 0 }); });

        // other initialization
        initState();
        resizeDisplay();
        updateUI();
        cache[cacheRef(state.seq, state.r, state.s)] = image.src;
        that.preload(state.seq);
        return that;
    };
});
