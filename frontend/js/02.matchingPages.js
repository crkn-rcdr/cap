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
      $("#matchingPageNavButtons").hide();
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
      }

      var $keywordSearch = $("#keywordSearch");
      if ($keywordSearch.length) {
        $keywordSearch.on("submit", $.proxy(this.submitSearch, this));
        $keywordSearch.on("reset", $.proxy(this.clearSearch, this));
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

    clearSearch: function (e) {
      e.preventDefault();
      this.params.q = "";
      this.$results.empty();
      $("#matchingImagesResults").hide();
      $("#matchingPageNavButtons").hide();
      $("#query").val('');
      sessionStorage.setItem("query", "");
    },

    makeCall: function () {
      var that = this;
      $("#matchingImagesResults").hide();
      $("#matchingPageNavButtons").hide();
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
      this.$searching.hide();
      this.$results.html(data.replace(/<\/a>/g, "</a>, ").replace(/,([^,]*)$/, '$1'));

      //matching-page

      if(window.location.href.includes("view")) {
        var previewWrap = $("#matching-pages-preview-wrap");
        previewWrap.html(previewWrap.html().replace(/,([^,]*)$/, '$1'));
        var previewLinks = $(".matching-page", previewWrap);

        var allWrap = $("#matching-pages-all-wrap");
        var allLinks = $(".matching-page", allWrap);
        $("#matching-page-count").html(allLinks.length);
        $("#matching-page-query").html(this.params.q);

        var prev = $("#matching-page-prev");
        var next = $("#matching-page-next");
        var currentMatchingPage = null;

        allLinks.each( ( i ) => {
          allLinks[i].addEventListener('click', () => {

            currentMatchingPage = i;

            if(currentMatchingPage === allLinks.length-1) {
              next.prop('disabled', true);
            } else {
              next.prop('disabled', false);
            }
            if(currentMatchingPage === 0) {
              prev.prop('disabled', true);
            } else {
              prev.prop('disabled', false);
            }
            
            allLinks[i].style = "font-style: italic; text-decoration: underline; color: #000000;";
            $("#matching-page-current").html(currentMatchingPage+1);
            if(previewLinks.length > i) {
              previewLinks[i].style = "font-style: italic; text-decoration: underline; color: #000000;";
            }

            allLinks.each( ( j ) => {
              if ( i !== j ) {
                allLinks[j].style = "";
                if(previewLinks.length > j) {
                  previewLinks[j].style = "";
                }
              }
            })

            $("#matchingPageNavButtons").show();

          }, false);
        })

        previewLinks.each( ( i ) => {
          previewLinks[i].addEventListener('click', () => {
            currentMatchingPage = i;
            if(currentMatchingPage === allLinks.length-1) {
              next.prop('disabled', true);
            } else {
              next.prop('disabled', false);
            }
            if(currentMatchingPage === 0) {
              prev.prop('disabled', true);
            } else {
              prev.prop('disabled', false);
            }
            previewLinks[i].style = "font-style: italic; text-decoration: underline; color: #000000;";;
            $("#matching-page-current").html(currentMatchingPage+1);
            allLinks[i].style = "font-style: italic; text-decoration: underline; color: #000000;";
            previewLinks.each( ( j ) => {
              if ( i !== j ) {
                previewLinks[j].style = "";
                allLinks[j].style = "";
              }
            })
            $("#matchingPageNavButtons").show();
          }, false);
        })

        if(prev) {
          prev.click(() => {
            var prevMatchingPage = currentMatchingPage - 1;
            if(prevMatchingPage > -1) { 
              allLinks[prevMatchingPage].click();
              $("#matching-page-current").html(prevMatchingPage+1);
            }
            if(prevMatchingPage > -1 && prevMatchingPage < previewLinks.length) { 
              previewLinks[prevMatchingPage].click();
              $("#matching-page-current").html(prevMatchingPage+1);
            }
            if(prevMatchingPage === 0) {
              prev.prop('disabled', true);
            } else {
              prev.prop('disabled', false);
            }
            next.prop('disabled', false);
          })
        }

        if(next) {
          next.click(() => {
            var nextMatchingPage = currentMatchingPage + 1;
            if(nextMatchingPage < allLinks.length) { 
              allLinks[nextMatchingPage].click();
              $("#matching-page-current").html(nextMatchingPage+1);
            }
            if(nextMatchingPage < previewLinks.length) { 
              previewLinks[nextMatchingPage].click();
              $("#matching-page-current").html(nextMatchingPage+1);
            }
            if(nextMatchingPage === allLinks.length-1) {
              next.prop('disabled', true);
            } else {
              next.prop('disabled', false);
            }
            prev.prop('disabled', false);
          })
        }
      }

      var $moreButton = $(".matching-pages-more", this.$results);
      var $lessButton = $(".matching-pages-less", this.$results);
      var $preview = $(".matching-pages-preview", this.$results);
      var $all = $(".matching-pages-all", this.$results);
      if ($moreButton.length) {
        $moreButton.on("click", function (e) {
          e.preventDefault();
          $moreButton.addClass("hidden");
          $preview.addClass("hidden");
          if ($lessButton.length)  $lessButton.removeClass("hidden");
          $all.removeClass("hidden");
        });
      }
      if ($lessButton.length) {
        $lessButton.on("click", function (e) {
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
