!(function ($) {
  var DragonViewer = function (element) {
    this.init("dragonViewer", element);
  };

  DragonViewer.prototype = {
    constructor: DragonViewer,

    init: function (type, element) {
      this.type = type;
      this.$element = $(element);

      this.loadData();
      this.setupViewer();
      this.setupTagView();
      this.setupHandlers();
      this.setupControls();

      var page = this.settings.initialPage;
      history.replaceState(page, null, this.makePathFromPage(page));

      // seems like a good enough place to load component data (that I'm not bothering with server-side)
      if (this.settings.hasTags) {
        this.fetchTagData(page);
      }

      this.pageUpdated(page);
      this.zoomUpdated(this.dragon.viewport.getZoom());
    },

    loadData: function () {
      var $e = this.$element;
      this.settings = {
        initialPage: parseInt($e.attr("data-seq"), 10) - 1,
        pkey: $e.attr("data-pkey"),
        total: parseInt($e.attr("data-total"), 10),
        portalName: $e.attr("data-portal-name"),
        documentLabel: $e.attr("data-document-label"),
        hasTags: !!$e.attr("data-tags"),
      };

      var pv = this;
      pv.components = [];
      var lastTaggedPage = -1;

      $("#pvPageSelect option").each(function (index) {
        var uriTemplate = this.getAttribute("data-uri");

        var component = {
          key: this.getAttribute("data-key"),
          uri:
            uriTemplate.slice(0, uriTemplate.indexOf("/full/")) + "/info.json",
          download: this.getAttribute("data-download"),
          label: this.innerHTML,
          fullImage: uriTemplate.replace("$SIZE", "max").replace("$ROTATE", 0),
        };

        if (pv.settings.hasTags) {
          component.hasTags = !!parseInt(this.getAttribute("data-tags"), 10);

          if (lastTaggedPage >= 0) {
            component.previousTags = lastTaggedPage;
            pv.components[lastTaggedPage].nextTags = index;
            lastTaggedPage = index;
          }
        }

        pv.components.push(component);
      });
    },

    setupViewer: function () {
      var pv = this;
      var viewerAnchor = "pvImageInner";

      $("#" + viewerAnchor).css("height", "800px");
      $("#" + viewerAnchor).css("width", "1000px");

      OpenSeadragon({
        id: viewerAnchor,
        prefixUrl: "/static/images/openseadragon/",
        tileSources: this.components.map(function (c) {
          return c.uri;
        }),
        sequenceMode: true,
        initialPage: this.settings.initialPage,
        showNavigationControl: false,
        showSequenceControl: false,
      });

      this.dragon = OpenSeadragon.getViewer(viewerAnchor);

      this.dragon.addHandler("page", function (_, page) {
        history.pushState(page, null, makePathFromPage(page));

        pv.fetchTagData(page);

        pv.pageUpdated(page);
      });

      this.dragon.addHandler("zoom", function (_, zoom) {
        pv.zoomUpdated(zoom);
      });
    },

    setupTagView: function () {
      var pve = function (selection) {
        return {
          selector: selection,
          show: function () {
            selection.removeClass("hidden");
          },
          hide: function () {
            selection.addClass("hidden");
          },
          toggle: function () {
            selection.toggleClass("hidden");
          },
        };
      };

      this.tagView = {
        frame: pve($("#pvComponent")),
        loading: pve($("#pvComponentLoading")),
        container: pve($("#pvComponentContainer")),
      };
    },

    setupHandlers: function () {
      this.firstPage = function () {
        this.dragon.goToPage(0);
      };
      this.previousPage = function () {
        this.dragon.goToPreviousPage();
      };
      this.nextPage = function () {
        this.dragon.goToNextPage();
      };
      this.lastPage = function () {
        this.dragon.goToPage(this.settings.total - 1);
      };
      this.selectPage = function () {
        this.dragon.goToPage(
          parseInt(this.controls.pageSelect.selector.val(), 10) - 1
        );
      };
      this.rotateLeft = function () {
        this.dragon.viewport.setRotation(
          (this.dragon.viewport.getRotation + 270) % 360
        );
      };
      this.rotateRight = function () {
        this.dragon.viewport.setRotation(
          (this.dragon.viewport.getRotation + 90) % 360
        );
      };
      this.zoomOut = function () {
        this.dragon.viewport.zoomBy(0.5);
      };
      this.zoomIn = function () {
        this.dragon.viewport.zoomBy(2);
      };
      this.toggleTags = function () {
        this.tagView.frame.toggle();
        this.controls.tagToggle.selector.toggleClass("active");
      };
      this.previousTaggedPage = function () {
        var page = this.dragon.getCurrentPage();
        var previousTags = this.components[page].previousTags;
        if (previousTags) {
          this.dragon.goToPage(previousTags);
        }
      };
      this.nextTaggedPage = function () {
        var page = this.dragon.getCurrentPage();
        var nextTags = this.components[page].nextTags;
        if (nextTags) {
          this.dragon.goToPage(nextTags);
        }
      };
    },

    setupControls: function () {
      // set up page viewer controls
      var pv = this;
      var pvc = function (spec) {
        return {
          selector: $(spec.selection),
          enable: function () {
            $(spec.selection).attr("href", "#0");
            this.selector.removeClass("disabled selected hidden");
            this.selector.off(spec.eventName).on(spec.eventName, function (e) {
              e.preventDefault();
              $.proxy(spec.handler, pv)();
            });
          },
          disable: function (className) {
            $(spec.selection).removeAttr("href");
            this.selector.addClass(className);
            this.selector.off(spec.eventName);
          },
        };
      };

      this.controls = {
        first: pvc({
          selection: "#pvFirst",
          eventName: "click",
          handler: this.firstPage,
        }),
        previous: pvc({
          selection: "#pvPrevious",
          eventName: "click",
          handler: this.previousPage,
        }),
        previousBar: pvc({
          selection: "#pvImgPrev",
          eventName: "click",
          handler: this.previousPage,
        }),
        next: pvc({
          selection: "#pvNext",
          eventName: "click",
          handler: this.nextPage,
        }),
        nextBar: pvc({
          selection: "#pvImgNext",
          eventName: "click",
          handler: this.nextPage,
        }),
        last: pvc({
          selection: "#pvLast",
          eventName: "click",
          handler: this.lastPage,
        }),
        pageSelect: pvc({
          selection: "#pvPageSelect",
          eventName: "change",
          handler: this.selectPage,
        }),
        rotateLeft: pvc({
          selection: "#pvRotateLeft",
          eventName: "click",
          handler: this.rotateLeft,
        }),
        rotateRight: pvc({
          selection: "#pvRotateRight",
          eventName: "click",
          handler: this.rotateRight,
        }),
        smaller: pvc({
          selection: "#pvSmaller",
          eventName: "click",
          handler: this.zoomOut,
        }),
        bigger: pvc({
          selection: "#pvBigger",
          eventName: "click",
          handler: this.zoomIn,
        }),
        tagToggle: pvc({
          selection: "#pvTagToggle",
          eventName: "click",
          handler: this.toggleTags,
        }),
        previousTags: pvc({
          selection: "#pvComponentPreviousLink",
          eventName: "click",
          handler: this.previousTaggedPage,
        }),
        nextTags: pvc({
          selection: "#pvComponentNextLink",
          eventName: "click",
          handler: this.nextTaggedPage,
        }),
      };

      // These never need to be disabled.
      this.controls.rotateLeft.enable();
      this.controls.rotateRight.enable();

      // TODO: replace this with some CSS transitions
      var imageLinks = $(".pv-imagelink");
      imageLinks.fadeTo(0, 0.5);
      imageLinks.on("mouseover", function (ev) {
        $(ev.delegateTarget).stop().fadeTo(400, 1);
      });
      imageLinks.on("mouseout", function (ev) {
        $(ev.delegateTarget).stop().fadeTo(400, 0.5);
      });
    },

    makePathFromPage: function (page) {
      var isPkeyOutFront =
        window.location.pathname.split("/").pop() === this.settings.pkey;
      return "" + (isPkeyOutFront ? this.settings.pkey + "/" : "") + (page + 1);
    },

    pageUpdated: function (page) {
      if (page <= 0) {
        this.controls.first.disable("disabled");
        this.controls.previous.disable("disabled");
        this.controls.previousBar.disable("hidden");
      } else {
        this.controls.first.enable();
        this.controls.previous.enable();
        this.controls.previousBar.enable();
      }
      if (page >= this.settings.total - 1) {
        this.controls.last.disable("disabled");
        this.controls.next.disable("disabled");
        this.controls.nextBar.disable("hidden");
      } else {
        this.controls.last.enable();
        this.controls.next.enable();
        this.controls.nextBar.enable();
      }

      this.controls.pageSelect.enable();
      this.controls.pageSelect.selector.val(page + 1);

      document.title =
        this.settings.documentLabel +
        " - " +
        this.components[page].label +
        " - " +
        this.settings.portalName;

      var $singleDownload = $("#pvDownloadSingle");
      var downloadUri = this.components[page].download;
      if (downloadUri) {
        $singleDownload.removeClass("hidden");
        $singleDownload.attr("href", downloadUri);
      } else {
        $singleDownload.addClass("hidden");
        $singleDownload.attr("href", "");
      }

      var $fullImage = $("#pvFullImage");
      if ($fullImage.length > 0) {
        $fullImage.attr("href", this.components[page].fullImage);
      }

      if (this.settings.hasTags) {
        this.controls.tagToggle.enable();
        if (this.components[page].previousTags) {
          $("#pvComponentPreviousSeq").text(
            this.components[this.components[page].previousTags].label
          );
          this.controls.previousTags.enable();
        } else {
          this.controls.previousTags.disable("hidden");
        }
        if (this.components[page].nextTags) {
          $("#pvComponentNextSeq").text(
            this.components[this.components[page].nextTags].label
          );
          this.controls.nextTags.enable();
        } else {
          this.controls.nextTags.disable("hidden");
        }
      }
    },

    zoomUpdated: function (zoom) {
      zoom <= this.dragon.viewport.getMinZoom()
        ? this.controls.smaller.disable("disabled")
        : this.controls.smaller.enable();
      zoom >= this.dragon.viewport.getMaxZoom()
        ? this.controls.bigger.disable("disabled")
        : this.controls.bigger.enable();
    },

    fetchTagData: function (page) {
      if (this.settings.hasTags) {
        this.tagView.container.selector.html("");
        if (this.components[page].hasTags) {
          this.controls.tagToggle.selector.addClass("btn-info");
          this.tagView.container.hide();
          this.tagView.loading.show();
          if (this.components[page].tags) {
            this.tagView.loading.hide();
            this.tagView.container.selector.html(this.components[page].tags);
            this.tagView.container.show();
          } else {
            var call = ["", "view", this.components[page].key].join("/");
            var pv = this;
            $.ajax({
              url: call,
              dataType: "html",
              data: { fmt: "ajax" },
              success: function (snippet) {
                pv.components[page].tags = snippet;
                pv.tagView.loading.hide();
                pv.tagView.container.selector.html(snippet);
                pv.tagView.container.show();
              },
              error: function () {
                pv.tagView.loading.hide();
              },
            });
          }
        } else {
          this.controls.tagToggle.selector.removeClass("btn-info");
          this.tagView.loading.hide();
          this.tagView.container.hide();
        }
      }
    },
  };

  $.fn.dragonViewer = function (option) {
    return this.each(function () {
      var $this = $(this);
      var data = $this.data("dragonViewer");
      if (!data) {
        $this.data("dragonViewer", (data = new DragonViewer(this)));
      }
      if (typeof option == "string") {
        data[option]();
      }
    });
  };

  $.fn.dragonViewer.Constructor = DragonViewer;
})(window.jQuery);
