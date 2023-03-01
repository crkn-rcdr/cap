/* cap.matchingPages.js */

!(function ($) {
  var MatchingPages = function (element) {
    this.init(element);
  };

  MatchingPages.prototype = {
    constructor: MatchingPages,

    init: function (element) {
      this.$element = $(element);
      this.$searching = $(".matching-pages-searching", this.$element);
      this.$results = $(".matching-pages-results", this.$element);
      this.callUrl = ["", "search", "post"].join("/");

      this.params = {
        q: $("<div/>").html(this.$element.attr("data-query")).text(),
        pkey: this.$element.attr("data-pkey"),
        fmt: "ajax",
        handler: "page",
      };

      if (!!this.params.q) {
        this.$searching.show();
        this.makeCall();
        $("#matchingImagesQuery").html(this.params.q);
      }

      var $keywordSearch = $("#keywordSearch");
      if ($keywordSearch.length) {
        $keywordSearch.on("submit", $.proxy(this.submitSearch, this));
      }

      var $pvToolbar = $("#pvToolbar");
      if ($pvToolbar.length) {
        var pageViewer = $pvToolbar.data().pageViewer;
        this.$element.on("click", ".matching-page", function (e) {
          e.preventDefault();
          pageViewer.controls.pageSelect.selector.val(
            parseInt($(this).attr("data-seq"), 10)
          );
          pageViewer.selectPage();
        });
      }
    },

    submitSearch: function (e) {
      e.preventDefault();
      var q = $('input[name="q"]', $("#keywordSearch")).val();
      this.params.q = q;
      sessionStorage.setItem("query", q);
      if (!!this.params.q) {
        this.$results.empty();
        this.$searching.show();
        this.makeCall();
      }
    },

    makeCall: function () {
      var that = this;
      $.ajax({
        url: this.callUrl,
        method: "post",
        dataType: "html",
        data: this.params,
        success: $.proxy(this.success, this),
        error: function (data) {
          that.$element.empty();
          that.$element.html("Error &mdash; Erreur");
        },
      });
    },

    success: function (data) {
      $("#matchingImagesResults").show();
      $("#matchingImagesQuery").html(this.params.q);
      this.$searching.hide();
      this.$results.html(data.replace(/<\/a>/g, "</a>, ").replace(/,([^,]*)$/, '$1'));

      var $moreButton = $(".matching-pages-more", this.$results);
      var $lessButton = $(".matching-pages-less", this.$results);
      var $preview = $(".matching-pages-preview", this.$results);
      var $all = $(".matching-pages-all", this.$results);
      if ($moreButton.length) {
        $moreButton.on("click", function (e) {
          console.log("mp")
          e.preventDefault();
          $moreButton.addClass("hidden");
          $preview.addClass("hidden");
          if ($lessButton.length)  $lessButton.removeClass("hidden");
          $all.removeClass("hidden");
        });
      }
      if ($lessButton.length) {
        $lessButton.on("click", function (e) {
          console.log("ls")
          e.preventDefault();
          $lessButton.addClass("hidden");
          $all.addClass("hidden");
          if ($moreButton.length) $moreButton.removeClass("hidden");
          $preview.removeClass("hidden");
        });
      }
    },
  };

  $.fn.matchingPages = function (option) {
    return this.each(function () {
      var $this = $(this);
      var data = $this.data("matchingPages");
      if (!data) {
        $this.data("matchingPages", (data = new MatchingPages(this)));
      }
      if (typeof option == "string") {
        data[option]();
      }
    });
  };

  $.fn.matchingPages.Constructor = MatchingPages;
})(window.jQuery);
