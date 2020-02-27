/* cap.pageViewer.js */

!(function($) {
  $.extend({
    preloadImages: function(uris) {
      var $cache = $("#imageCache");

      $.map(uris, function(uri) {
        $cache.append('<img src="' + uri + '" alt="" />');
      });
    }
  });

  var PageViewer = function(element) {
    this.init("pageViewer", element);
  };

  PageViewer.prototype = {
    constructor: PageViewer,

    init: function(type, element) {
      this.type = type;
      this.$element = $(element);

      this.loadData();
      this.loadComponents();
      this.setupDisplay();
      this.setupHandlers();
      this.setupControls();

      // image reference cache
      this.imageCache = {};

      this.initState();
      this.updateUI();
      this.setBindings();
      this.imageCache[
        this.imageCacheRef([this.state.seq, this.state.r, this.state.s])
      ] = this.image.attr("src");
      this.preload(this.state.seq);
    },

    loadData: function() {
      var $e = this.$element;
      this.state = {
        seq: parseInt($e.attr("data-seq"), 10),
        r: parseInt($e.attr("data-rotation"), 10),
        s: parseInt($e.attr("data-size"), 10)
      };
      this.settings = {
        token: $e.attr("data-token"),
        pkey: $e.attr("data-pkey"),
        total: parseInt($e.attr("data-total"), 10),
        portalName: $e.attr("data-portal-name"),
        documentLabel: $e.attr("data-document-label"),
        hasTags: !!$e.attr("data-tags"),
        // TODO: load this from config
        rotates: { 0: "0", 1: "90", 2: "180", 3: "270" },
        sizes: {
          1: "800",
          2: "1024",
          3: "1296",
          4: "1600",
          5: "2048",
          6: "2560"
        },
        minSize: 1,
        maxSize: 6
      };
    },

    setupDisplay: function() {
      this.image = $("#pvImg");

      // set up page viewer element objects
      var pve = function(selection) {
        return {
          selector: selection,
          show: function() {
            selection.removeClass("hidden");
          },
          hide: function() {
            selection.addClass("hidden");
          },
          toggle: function() {
            selection.toggleClass("hidden");
          }
        };
      };

      this.display = {
        container: pve($("#pvImageContainer")),
        toolbar: pve($("#pvToolbar")),
        loading: pve($("#pvLoading")),
        error: pve($("#pvError")),
        component: {
          frame: pve($("#pvComponent")),
          loading: pve($("#pvComponentLoading")),
          container: pve($("#pvComponentContainer"))
        }
      };
    },

    setupHandlers: function() {
      this.firstPage = function() {
        this.updateState({ seq: 1 });
      };
      this.previousPage = function() {
        this.updateState({ seq: this.state.seq - 1 });
      };
      this.nextPage = function() {
        this.updateState({ seq: this.state.seq + 1 });
      };
      this.lastPage = function() {
        this.updateState({ seq: this.settings.total });
      };
      this.goToPage = function(page) {
        this.updateState({ seq: page });
      };
      this.selectPage = function() {
        this.goToPage(parseInt(this.controls.pageSelect.selector.val(), 10));
      };
      this.rotateLeft = function() {
        this.updateState({ r: (this.state.r + 3) % 4 });
      };
      this.rotateRight = function() {
        this.updateState({ r: (this.state.r + 1) % 4 });
      };
      this.smaller = function() {
        this.updateState({ s: this.state.s - 1 });
      };
      this.bigger = function() {
        this.updateState({ s: this.state.s + 1 });
      };
      this.toggleTags = function() {
        this.display.component.frame.toggle();
        this.controls.tagToggle.selector.toggleClass("active");
      };
      this.previousTaggedPage = function() {
        this.updateState({
          seq: this.components[this.state.seq].previousTags || this.state.seq
        });
      };
      this.nextTaggedPage = function() {
        this.updateState({
          seq: this.components[this.state.seq].nextTags || this.state.seq
        });
      };
    },

    setupControls: function() {
      // set up page viewer controls
      var pv = this;
      var pvc = function(spec) {
        $(spec.selection).attr("href", "#0");
        return {
          selector: $(spec.selection),
          enable: function() {
            this.selector.removeClass("disabled selected hidden");
            this.selector.off(spec.eventName).on(spec.eventName, function(e) {
              e.preventDefault();
              $.proxy(spec.handler, pv)();
            });
          },
          disable: function(className) {
            this.selector.addClass(className);
            this.selector.off(spec.eventName);
          }
        };
      };

      this.controls = {
        first: pvc({
          selection: "#pvFirst",
          eventName: "click",
          handler: this.firstPage
        }),
        previous: pvc({
          selection: "#pvPrevious",
          eventName: "click",
          handler: this.previousPage
        }),
        previousBar: pvc({
          selection: "#pvImgPrev",
          eventName: "click",
          handler: this.previousPage
        }),
        next: pvc({
          selection: "#pvNext",
          eventName: "click",
          handler: this.nextPage
        }),
        nextBar: pvc({
          selection: "#pvImgNext",
          eventName: "click",
          handler: this.nextPage
        }),
        last: pvc({
          selection: "#pvLast",
          eventName: "click",
          handler: this.lastPage
        }),
        pageSelect: pvc({
          selection: "#pvPageSelect",
          eventName: "change",
          handler: this.selectPage
        }),
        rotateLeft: pvc({
          selection: "#pvRotateLeft",
          eventName: "click",
          handler: this.rotateLeft
        }),
        rotateRight: pvc({
          selection: "#pvRotateRight",
          eventName: "click",
          handler: this.rotateRight
        }),
        smaller: pvc({
          selection: "#pvSmaller",
          eventName: "click",
          handler: this.smaller
        }),
        bigger: pvc({
          selection: "#pvBigger",
          eventName: "click",
          handler: this.bigger
        }),
        tagToggle: pvc({
          selection: "#pvTagToggle",
          eventName: "click",
          handler: this.toggleTags
        }),
        previousTags: pvc({
          selection: "#pvComponentPreviousLink",
          eventName: "click",
          handler: this.previousTaggedPage
        }),
        nextTags: pvc({
          selection: "#pvComponentNextLink",
          eventName: "click",
          handler: this.nextTaggedPage
        })
      };
    },

    makePathFromState: function(st) {
      var isPkeyOutFront =
        window.location.pathname.split("/").pop() === this.settings.pkey;
      return (
        "" +
        (isPkeyOutFront ? this.settings.pkey + "/" : "") +
        st.seq +
        "?r=" +
        st.r +
        "&s=" +
        st.s
      );
    },

    loadComponents: function() {
      var pv = this;
      pv.components = {};

      // first pass: load data
      $("#pvPageSelect option").each(function(index, element) {
        pv.components[this.value] = {
          key: this.getAttribute("data-key"),
          uri: this.getAttribute("data-uri"),
          label: this.innerHTML
        };

        if (pv.settings.hasTags) {
          pv.components[this.value].hasTags = !!parseInt(
            this.getAttribute("data-tags"),
            10
          );
        }
      });

      // second pass: determine previous/next tags
      if (pv.settings.hasTags) {
        var previousTagMarker = 0;
        var nextTagMarker = 1;

        for (var i = 1; i <= this.settings.total; i++) {
          pv.components[i].previousTags = previousTagMarker;

          if (nextTagMarker === i) {
            var j = i + 1;
            while (j <= this.settings.total) {
              if (pv.components[j].hasTags) {
                nextTagMarker = j;
                break;
              }
              j++;
            }

            if (nextTagMarker === i) {
              nextTagMarker = Infinity;
            }
          }
          pv.components[i].nextTags = nextTagMarker;

          if (pv.components[i].hasTags) {
            previousTagMarker = i;
          }
        }
      }
    },

    hashToState: function(hash) {
      var kvs = hash.split("&");
      var st = {};
      $.each(kvs, function(kv) {
        var equalsIndex = kv.toString().indexOf("=");
        if (equalsIndex > 0 && equalsIndex < kv.length - 1) {
          var split = kv.split("=");
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
      return st;
    },

    imageCacheRef: function(seq, r, s) {
      return [seq, r, s].join(",");
    },

    initState: function() {
      history.replaceState(
        this.sanitizeState(this.state),
        null,
        this.makePathFromState(this.state)
      );

      // see note in updateState
      this.stateChanged();

      // seems like a good enough place to load component data (that I'm not bothering with server-side)
      if (this.settings.hasTags) {
        this.fetchComponentData(this.state.seq);
      }
    },

    updateState: function(newState) {
      var st = $.extend({}, this.state, newState);
      // only update state if the state has changed
      if (
        !(
          st.seq === this.state.seq &&
          st.r === this.state.r &&
          st.s === this.state.s
        )
      ) {
        this.display.loading.show();
        history.pushState(
          this.sanitizeState(st),
          null,
          this.makePathFromState(st)
        );

        // unlike the old History.js method, popstate only fires when the user
        // triggers the history change directly (back button, etc.)
        this.stateChanged();
      }
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
      this.state.s <= this.settings.minSize
        ? this.controls.smaller.disable("disabled")
        : this.controls.smaller.enable();
      this.state.s >= this.settings.maxSize
        ? this.controls.bigger.disable("disabled")
        : this.controls.bigger.enable();

      var itemName = this.controls.pageSelect.selector
        .find("#seq" + this.state.seq)
        .html();
      document.title =
        this.settings.documentLabel +
        " - " +
        itemName +
        " - " +
        this.settings.portalName;

      if (this.settings.hasTags) {
        this.controls.tagToggle.enable();
        if (this.components[this.state.seq].previousTags > 0) {
          $("#pvComponentPreviousSeq").text(
            this.components[this.components[this.state.seq].previousTags].label
          );
          this.controls.previousTags.enable();
        } else {
          this.controls.previousTags.disable("hidden");
        }
        if (this.components[this.state.seq].nextTags < this.settings.total) {
          $("#pvComponentNextSeq").text(
            this.components[this.components[this.state.seq].nextTags].label
          );
          this.controls.nextTags.enable();
        } else {
          this.controls.nextTags.disable("hidden");
        }
      }
    },

    getUri: function(seq, uriTemplate) {
      var uri = uriTemplate;
      uri = uri.replace("$TOKEN", this.settings.token);
      uri = uri.replace("$ROTATE", this.settings.rotates[this.state.r] || "0");
      var size = this.settings.sizes[this.state.s] || "800";
      uri = uri.replace("$SIZE", "!" + size + "," + size);

      var ref = this.imageCacheRef(seq, this.state.r, this.state.s);
      this.imageCache[ref] = uri;
      $.preloadImages([uri]);
    },

    preload: function(seq) {
      var pv = this;
      $.each([seq, seq - 1, seq + 1, seq + 2, seq + 3], function(
        index,
        newSeq
      ) {
        var ref = pv.imageCacheRef(newSeq, pv.state.r, pv.state.s);
        if (newSeq >= 1 && newSeq <= pv.settings.total && !pv.imageCache[ref]) {
          pv.getUri(newSeq, pv.components[newSeq].uri);
        }
      });
    },

    requestImage: function() {
      var uri = this.imageCache[
        this.imageCacheRef(this.state.seq, this.state.r, this.state.s)
      ];
      if (uri && uri !== "error") {
        this.image.attr("src", uri);
        this.display.error.hide();
        this.display.container.show();
      } else if (!uri) {
        setTimeout($.proxy(this.requestImage, this), 1000);
      }
    },

    stateChanged: function() {
      this.state = this.sanitizeState(history.state);
      this.preload(this.state.seq);
      this.requestImage();

      if (this.settings.hasTags) {
        this.fetchComponentData(this.state.seq);
      }

      this.updateUI();
    },

    fetchComponentData: function(seq) {
      this.display.component.container.selector.html("");
      if (this.components[seq].hasTags) {
        this.controls.tagToggle.selector.addClass("btn-info");
        this.display.component.container.hide();
        this.display.component.loading.show();
        if (this.components[seq].tags) {
          this.display.component.loading.hide();
          this.display.component.container.selector.html(
            this.components[seq].tags
          );
          this.display.component.container.show();
        } else {
          var call = ["", "view", this.components[seq].key].join("/");
          var pv = this;
          $.ajax({
            url: call,
            dataType: "html",
            data: { fmt: "ajax" },
            success: function(snippet) {
              pv.components[seq].tags = snippet;
              pv.display.component.loading.hide();
              pv.display.component.container.selector.html(snippet);
              pv.display.component.container.show();
            },
            error: function() {
              pv.display.component.loading.hide();
            }
          });
        }
      } else {
        this.controls.tagToggle.selector.removeClass("btn-info");
        this.display.component.loading.hide();
        this.display.component.container.hide();
      }
    },

    imageLoaded: function() {
      this.display.loading.hide();
      this.display.error.hide();
      this.image.attr(
        "alt",
        this.controls.pageSelect.selector.find("option:selected").text()
      );
    },

    imageError: function() {
      this.display.loading.hide();
      this.display.container.hide();
      this.display.error.show();
    },

    setBindings: function() {
      window.onpopstate = $.proxy(this.stateChanged, this);
      this.image.on("load", $.proxy(this.imageLoaded, this));
      this.image.on("error", $.proxy(this.imageError, this));

      var imageLinks = $(".pv-imagelink");
      imageLinks.fadeTo(0, 0.5);
      imageLinks.on("mouseover", function(ev) {
        $(ev.delegateTarget)
          .stop()
          .fadeTo(400, 1);
      });
      imageLinks.on("mouseout", function(ev) {
        $(ev.delegateTarget)
          .stop()
          .fadeTo(400, 0.5);
      });
    }
  };

  $.fn.pageViewer = function(option) {
    return this.each(function() {
      var $this = $(this);
      var data = $this.data("pageViewer");
      if (!data) {
        $this.data("pageViewer", (data = new PageViewer(this)));
      }
      if (typeof option == "string") {
        data[option]();
      }
    });
  };

  $.fn.pageViewer.Constructor = PageViewer;
})(window.jQuery);
