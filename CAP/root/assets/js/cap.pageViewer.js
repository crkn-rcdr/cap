/* cap.pageViewer.js */

!(function($) {
    var PageViewer = function(element) {
        this.init('pageViewer', element);
    }

    PageViewer.prototype = {
        constructor: PageViewer,

        init: function(type, element) {
            this.type = type;
            this.$element = $(element);

            this.loadData();
            this.setupDisplay();
            this.setupHandlers();
            this.setupControls();

            // image reference cache
            this.cache = {};

            this.initState();
            this.updateUI();
            this.setBindings();
            this.cache[this.cacheRef([this.state.seq, this.state.r, this.state.s])] = this.image.attr('src');
            this.preload(this.state.seq);
        },

        loadData: function() {
            var $e = this.$element;
            this.state = {
                seq: parseInt($e.attr('data-seq'), 10),
                r: parseInt($e.attr('data-rotation'), 10),
                s: parseInt($e.attr('data-size'), 10)
            };
            this.settings = {
                pkey: $e.attr('data-pkey'),
                total: parseInt($e.attr('data-total'), 10),
                minSize: parseInt($e.attr('data-min-size'), 10),
                maxSize: parseInt($e.attr('data-max-size'), 10),
                canResize: !!parseInt($e.attr('data-resize'), 10),
                portalName: $e.attr('data-portal-name'),
                documentLabel: $e.attr('data-document-label')
            };
        },

        setupDisplay: function() {
            this.image = $("#pvImg");
            
            // set up page viewer element objects
            var pve = function(selection) {
                return {
                    show: function() { selection.removeClass('hidden'); },
                    hide: function() { selection.addClass('hidden'); }
                };
            };

            this.display = {
                container: pve($('#pvImageContainer')),
                toolbar: pve($('#pvToolbar')),
                loading: pve($('#pvLoading')),
                error: pve($('#pvError')),
                subscribe: pve($('#pvSubscribe'))
            };
        },

        setupHandlers: function() {
            this.firstPage = function() { this.updateState({ seq: 1 }); };
            this.previousPage = function() { this.updateState({ seq: this.state.seq - 1 }); };
            this.nextPage = function() { this.updateState({ seq: this.state.seq + 1 }); };
            this.lastPage = function() { this.updateState({ seq: this.settings.total }); };
            this.goToPage = function(page) { this.updateState({ seq: page }); };
            this.selectPage = function() { this.goToPage(parseInt(this.controls.pageSelect.selector.val(), 10)); };
            this.rotateLeft = function() { this.updateState({ r: (this.state.r + 3) % 4 }); };
            this.rotateRight = function() { this.updateState({ r: (this.state.r + 1) % 4 }); };
            this.smaller = function() { this.updateState({ s: this.state.s - 1 }); };
            this.bigger = function() { this.updateState({ s: this.state.s + 1 }); };
        },

        setupControls: function() {
            // set up page viewer controls
            var pv = this;
            var pvc = function(spec) {
                $(spec.selection).removeAttr('href');
                return {
                    selector: $(spec.selection),
                    enable: function() {
                        this.selector.removeClass('disabled selected hidden');
                        if (!(this.selector.data('events') && this.selector.data('events')[spec.eventName])) {
                            this.selector.on(spec.eventName + '.pv', $.proxy(spec.handler, pv));
                        }
                    },
                    disable: function(className) {
                        this.selector.addClass(className);
                        this.selector.off(spec.eventName + '.pv');
                    }
                };
            };
            
            this.controls = {
                first: pvc({ selection: "#pvFirst", eventName: "click", handler: this.firstPage }),
                previous: pvc({ selection: "#pvPrevious", eventName: "click", handler: this.previousPage }),
                previousBar: pvc({ selection: "#pvImgPrev", eventName: "click", handler: this.previousPage }),
                next: pvc({ selection: "#pvNext", eventName: "click", handler: this.nextPage }),
                nextBar: pvc({ selection: "#pvImgNext", eventName: "click", handler: this.nextPage }),
                last: pvc({ selection: "#pvLast", eventName: "click", handler: this.lastPage }),
                pageSelect: pvc({ selection: "#pvPageSelect", eventName: "change", handler: this.selectPage }),
                rotateLeft: pvc({ selection: "#pvRotateLeft", eventName: "click", handler: this.rotateLeft }),
                rotateRight: pvc({ selection: "#pvRotateRight", eventName: "click", handler: this.rotateRight }),
                smaller: pvc({ selection: "#pvSmaller", eventName: "click", handler: this.smaller }),
                bigger: pvc({ selection: "#pvBigger", eventName: "click", handler: this.bigger })
            };
        },

        makePathFromState: function(st) {
            var isPkeyOutFront = window.location.pathname.split('/').pop() === this.settings.pkey;
            return "" + (isPkeyOutFront ? this.settings.pkey + "/" : "") + st.seq + "?r=" + st.r + "&s=" + st.s;
        },

        hashToState: function(hash) {
            var kvs = hash.split('&');
            var st = {};
            $.each(kvs, function(kv) {
                var equalsIndex = kv.toString().indexOf('=');
                if (equalsIndex > 0 && equalsIndex < (kv.length - 1)) {
                    var split = kv.split('=');
                    kv[split[0]] = split[1];
                }
            });
            return st;
        },

        sanitizeState: function(st) {
            if (st.seq < 1) st.seq = 1;
            if (st.seq > this.settings.total) st.seq = this.settings.total;
            if (st.r > 3 || st.r < 0) st.r = 0;
            if (st.s < this.settings.minSize) st.s = this.settings.minSize;
            if (st.s > this.settings.maxSize) st.s = this.settings.maxSize;
            if (!this.settings.canResize) st.s = this.settings.minSize;
            return st;
        },

        hasPageAccess: function(seq) {
            var item = this.controls.pageSelect.selector.find('#seq' + seq);
            return !!parseInt(item.data('access'), 10);
        },

        cacheRef: function(seq, r, s) {
            return [seq, r, s].join(',');
        },

        initState: function() {
            var hash = History.getHash();
            if (hash) $.extend(this.state, this.hashToState(hash));
            History.replaceState(this.sanitizeState(this.state), null, this.makePathFromState(this.state));
        },

        updateState: function(newState) {
            var st = $.extend({}, this.state, newState);
            this.display.loading.show();
            History.pushState(this.sanitizeState(st), null, this.makePathFromState(st));
        },

        updateUI: function() {
            if (this.state.seq <= 1) {
                this.controls.first.disable("disabled");
                this.controls.previous.disable("disabled");
                this.controls.previousBar.disable("hidden");
            } else {
                this.controls.first.enable();
                this.controls.previous.enable();
                this.controls.previousBar.enable();
            }
            if (this.state.seq >= this.settings.total) {
                this.controls.last.disable("disabled");
                this.controls.next.disable("disabled");
                this.controls.nextBar.disable("hidden");
            } else {
                this.controls.last.enable();
                this.controls.next.enable();
                this.controls.nextBar.enable();
            }

            this.controls.pageSelect.enable();
            this.controls.pageSelect.selector.val(this.state.seq);
            this.controls.rotateLeft.enable();
            this.controls.rotateRight.enable();
            (this.state.s <= this.settings.minSize || !this.settings.canResize) ? this.controls.smaller.disable("disabled") : this.controls.smaller.enable();
            (this.state.s >= this.settings.maxSize || !this.settings.canResize) ? this.controls.bigger.disable("disabled") : this.controls.bigger.enable();

            var itemName = this.controls.pageSelect.selector.find('#seq' + this.state.seq).html();
            document.title = this.settings.documentLabel + " - " + itemName + " - " + this.settings.portalName;
        },

        getUri: function(seq) {
            var args = { r: this.state.r, s: this.state.s, fmt: 'ajax' };
            var call = ['', 'file', 'get_page_uri', this.settings.pkey, seq].join('/');
            var ref = this.cacheRef(seq, this.state.r, this.state.s);
            var pv = this;
            $.ajax({
                url: call,
                dataType: 'json',
                data: args,
                success: function(data) {
                    if (data['status'] === 200) {
                        pv.cache[ref] = data.uri;
                        $.preloadImages([data.uri]);
                    } else {
                        pv.cache[ref] = 'error';
                    }
                },
                error: function() {
                    setTimeout($.proxy(function() { this.getUri(seq); }, pv), 1000);
                }
            });
        },

        preload: function(seq) {
            var pv = this;
            $.each([seq, seq - 1, seq + 1, seq + 2, seq + 3], function(index, newSeq) {
                var ref = pv.cacheRef(newSeq, pv.state.r, pv.state.s);
                if (newSeq >= 1 &&
                    newSeq <= pv.settings.total &&
                    pv.hasPageAccess(newSeq) &&
                    (pv.state.s === pv.settings.minSize || pv.settings.canResize) &&
                    !pv.cache[ref]) {
                    pv.getUri(newSeq);
                }
            });
        },

        requestImage: function() {
            var uri = this.cache[this.cacheRef(this.state.seq, this.state.r, this.state.s)];
            if (uri && uri !== 'error') {
                this.image.attr('src', uri);
                this.display.subscribe.hide();
                this.display.error.hide();
                this.display.container.show();
            } else if (!uri) {
                setTimeout($.proxy(this.requestImage, this), 1000);
            }
        },

        stateChanged: function() {
            this.state = this.sanitizeState(History.getState().data);
            this.preload(this.state.seq);
            if (this.hasPageAccess(this.state.seq) && (this.state.s == this.settings.minSize || this.settings.canResize)) {
                this.requestImage();
            } else {
                this.display.container.hide();
                this.display.loading.hide();
                this.display.subscribe.show();
            }
            this.updateUI();
        },

        imageLoaded: function() {
            this.display.loading.hide();
            this.display.error.hide();
            this.display.subscribe.hide();
        },

        imageError: function() {
            this.display.loading.hide();
            this.display.container.hide();
            this.display.subscribe.hide();
            this.display.error.show();
        },

        setBindings: function() {
            History.Adapter.bind(window, 'statechange', $.proxy(this.stateChanged, this));
            this.image.on('load', $.proxy(this.imageLoaded, this));
            this.image.on('error', $.proxy(this.imageError, this));

            var imageLinks = $('.pv-imagelink');
            imageLinks.fadeTo(0, 0.2);
            imageLinks.on('mouseover', function(ev) { $(ev.delegateTarget).stop().fadeTo(400, 1); });
            imageLinks.on('mouseout', function(ev) { $(ev.delegateTarget).stop().fadeTo(400, 0.2); });
        }
    };

    $.fn.pageViewer = function(option) {
        return this.each(function() {
            var $this = $(this);
            var data = $this.data('pageViewer');
            if (!data) { $this.data('pageViewer', (data = new PageViewer(this))); }
            if (typeof option == 'string') { data[option](); }
        });
    };

    $.fn.pageViewer.Constructor = PageViewer;
}(window.jQuery));