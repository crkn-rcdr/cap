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
        imageLoadErrorString: $e.attr("data-load-error"),
      };

      var pv = this;
      pv.components = [];

      $("#pvPageSelect option").each(function (index) {
        var uri = this.getAttribute("data-uri");

        var component = {
          uri: uri,
          download: this.getAttribute("data-download"),
          label: this.innerHTML,
          fullImage:
            uri.slice(0, uri.indexOf("/info.json")) + "/full/max/0/default.jpg",
        };

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
        this.searchView.frame.toggle();
        this.controls.searchToggle.selector.toggleClass("active");
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
      this.downloadFullImage = function () {
        var downloadButton = document.getElementById("pvFullImageDownload");
        var url = downloadButton.getAttribute("data-url");
        $.ajax({
          url: url,
          method: "get",
          xhrFields:{
              responseType: 'blob'
          },
          success: function(data) {
            var slug = downloadButton.getAttribute("data-slug");
            var seq = downloadButton.getAttribute("data-seq");
            var filename = slug + "." + seq + '.jpg';

            if (window.navigator.msSaveOrOpenBlob) {
              // Internet Explorer
              window.navigator.msSaveOrOpenBlob(data, {type: "image/jpg"}, filename);
            } else {
              var url = URL.createObjectURL(data);
              var a = document.createElement('a');
              a.href = url;
              a.download = filename;
              document.body.appendChild(a); // we need to append the element to the dom -> otherwise it will not work in firefox
              a.click();
              a.remove();  //afterwards we remove the element again
            }

            a.click();
          },
          error: function (data) {
            that.$element.empty();
            that.$element.html("Error &mdash; Erreur");
          },
        });
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
        fullImageDownload: pvc({
          selection: "#pvFullImageDownload",
          eventName: "click",
          handler: this.downloadFullImage,
        }),
      };

      // These never need to be disabled.
      this.controls.rotateLeft.enable();
      this.controls.rotateRight.enable();
      this.controls.searchToggle.enable();
      this.controls.fullImageDownload.enable();

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
    },

    zoomUpdated: function (zoom) {
      zoom <= this.dragon.viewport.getMinZoom()
        ? this.controls.smaller.disable("disabled")
        : this.controls.smaller.enable();
      zoom >= this.dragon.viewport.getMaxZoom()
        ? this.controls.bigger.disable("disabled")
        : this.controls.bigger.enable();
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
