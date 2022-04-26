!(function ($) {
  var DragonViewer = function (element) {
    this.init("dragonViewer", element);
  };

  DragonViewer.prototype = {
    constructor: DragonViewer,

    init: function (type, element) {
      this.type = type;
      this.$element = $(element);

      $("#pvImg").remove();

      this.loadData();
      this.setupViewer();
      this.setupOverlays();
      this.setupHandlers();
      this.setupControls();
      this.setupFullscreen();

      var page = this.settings.initialPage;
      history.replaceState({ page: page }, null, this.makePathFromPage(page));

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
        imageLoadErrorString: $e.attr("data-load-error"),
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
          }

          if (component.hasTags) {
            for (var i = Math.max(0, lastTaggedPage); i < index; i++) {
              pv.components[i].nextTags = index;
            }
            lastTaggedPage = index;
          }
        }

        pv.components.push(component);
      });
    },

    setupViewer: function () {
      var pv = this;
      var viewerAnchor = "pvImageInner";

      OpenSeadragon.setString(
        "Errors.OpenFailed",
        pv.settings.imageLoadErrorString
      );

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
        showNavigator: true,
        navigatorPosition: "TOP_LEFT",
        crossOriginPolicy: "Anonymous",
        preserveViewport: true,
      });

      this.dragon = OpenSeadragon.getViewer(viewerAnchor);

      this.dragon.addHandler("page", function (event) {
        var page = event.page;

        if (!pv.isOnPopState) {
          history.replaceState({ page: page }, null, pv.makePathFromPage(page));
        }
        pv.isOnPopState = false;

        pv.fetchTagData(page);
        pv.pageUpdated(page);
      });

      this.dragon.addHandler("zoom", function (event) {
        pv.zoomUpdated(event.zoom);
      });

      window.onpopstate = function (event) {
        pv.isOnPopState = true;
        pv.dragon.goToPage(event.state.page);
      };

      // Determines whether the next state change should push onto the history;
      // it shouldn't if the state change comes from a popstate (e.g. browser "back")
      this.isOnPopState = false;
    },

    setupOverlays: function () {
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

      this.searchView = {
        frame: pve($("#pvSearch")),
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
          (this.dragon.viewport.degrees + 270) % 360
        );
      };
      this.rotateRight = function () {
        this.dragon.viewport.setRotation(
          (this.dragon.viewport.degrees + 90) % 360
        );
      };
      this.zoomOut = function () {
        var zoom = this.dragon.viewport.getZoom();
        var minZoom = this.dragon.viewport.getMinZoom();
        this.dragon.viewport.zoomTo(Math.max(zoom * 0.5, minZoom));
      };
      this.zoomIn = function () {
        var zoom = this.dragon.viewport.getZoom();
        var maxZoom = this.dragon.viewport.getMaxZoom();
        this.dragon.viewport.zoomTo(Math.min(zoom * 2, maxZoom));
      };
      this.toggleSearch = function () {
        this.tagView.frame.hide();
        this.searchView.frame.toggle();
        this.controls.searchToggle.selector.toggleClass("active");
      };
      this.toggleTags = function () {
        this.searchView.frame.hide();
        this.tagView.frame.toggle();
        this.controls.tagToggle.selector.toggleClass("active");
      };
      this.previousTaggedPage = function () {
        var page = this.dragon.currentPage();
        var previousTags = this.components[page].previousTags;
        if (previousTags) {
          this.dragon.goToPage(previousTags);
        }
      };
      this.nextTaggedPage = function () {
        var page = this.dragon.currentPage();
        var nextTags = this.components[page].nextTags;
        if (nextTags) {
          this.dragon.goToPage(nextTags);
        }
      };
      this.enterFullscreen = function () {
        if (!document.fullscreenElement) {
          var pane = document.getElementById("pvPane");
          pane.requestFullscreen();
        }
      };
      this.exitFullscreen = function () {
        if (document.exitFullscreen) {
          document.exitFullscreen();
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
            this.selector.prop("disabled", false);
            this.selector.removeAttr("href");
            this.selector.removeClass("disabled selected hidden");
            this.selector.off(spec.eventName).on(spec.eventName, function (e) {
              e.preventDefault();
              $.proxy(spec.handler, pv)();
            });
          },
          disable: function (className) {
            this.selector.prop("disabled", true);
            this.selector.tooltip("hide");
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
        next: pvc({
          selection: "#pvNext",
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
        searchToggle: pvc({
          selection: "#pvSearchToggle",
          eventName: "click",
          handler: this.toggleSearch,
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
        fullscreenEnter: pvc({
          selection: "#pvFullscreenEnter",
          eventName: "click",
          handler: this.enterFullscreen,
        }),
        fullscreenExit: pvc({
          selection: "#pvFullscreenExit",
          eventName: "click",
          handler: this.exitFullscreen,
        }),
      };

      // These never need to be disabled.
      this.controls.rotateLeft.enable();
      this.controls.rotateRight.enable();
      this.controls.searchToggle.enable();

      // This should be enabled now, because we don't have control over it
      this.controls.fullscreenEnter.enable();
    },

    setupFullscreen: function () {
      var pane = document.getElementById("pvPane");
      var pv = this;
      var $container = $("#pvImageInner");
      var initialHeight = $container.css("height");
      pane.onfullscreenchange = function (event) {
        var pane = event.target;
        if (document.fullscreenElement === pane) {
          var $toolbarTop = $("#pvToolbar");
          var $toolbarBottom = $("#pvToolbarBottom");
          // This is unfortunate, but I don't want to think too hard about it
          var toolbarHeights =
            $toolbarBottom.height() + $toolbarTop.height() + 4;
          $container.css("height", "calc(100vh - " + toolbarHeights + "px)");
          pv.controls.fullscreenEnter.disable("hidden");
          pv.controls.fullscreenExit.enable();
        } else {
          $container.css("height", initialHeight);
          pv.controls.fullscreenExit.disable("hidden");
          pv.controls.fullscreenEnter.enable();
        }
      };
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
      } else {
        this.controls.first.enable();
        this.controls.previous.enable();
      }
      if (page >= this.settings.total - 1) {
        this.controls.last.disable("disabled");
        this.controls.next.disable("disabled");
      } else {
        this.controls.last.enable();
        this.controls.next.enable();
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
      var data = $this.data("pageViewer");
      if (!data) {
        $this.data("pageViewer", (data = new DragonViewer(this)));
      }
      if (typeof option == "string") {
        data[option]();
      }
    });
  };

  $.fn.dragonViewer.Constructor = DragonViewer;
})(window.jQuery);
