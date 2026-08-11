!(function ($) {
  var downloads = {
    fetchUri: function (downloadUrl) {
      var deferred = $.Deferred();

      if (!downloadUrl) {
        deferred.resolve(null);
        return deferred.promise();
      }

      $.ajax({
        url: downloadUrl,
        method: "get",
        dataType: "json",
        cache: false,
        success: function (data) {
          deferred.resolve(
            data && data.download_uri ? data.download_uri : null
          );
        },
        error: function () {
          deferred.resolve(null);
        },
      });

      return deferred.promise();
    },

    resolveUri: function (downloadUrl) {
      return downloads.fetchUri(downloadUrl);
    },

    setLink: function ($link, uri) {
      if (uri) {
        $link.prop("disabled", false);
        $link.removeAttr("disabled");
        $link.attr("aria-disabled", "false");
        $link.removeClass("disabled");
        $link.attr("href", uri);
      } else {
        $link.prop("disabled", true);
        $link.attr("disabled", "disabled");
        $link.attr("aria-disabled", "true");
        $link.addClass("disabled");
        $link.removeAttr("href");
      }
    },

    setLoading: function ($link, loading) {
      if (!$link || $link.length === 0) {
        return;
      }

      if (loading) {
        if (!$link.data("cap-original-html")) {
          $link.data("cap-original-html", $link.html());
        }
        $link.prop("disabled", true);
        $link.attr("disabled", "disabled");
        $link.attr("aria-busy", "true");
        $link.addClass("disabled");
        $link.html(
          '<img class="full-size-download-spinner" src="/static/images/spinner.gif" alt="">'
        );
      } else {
        var originalHtml = $link.data("cap-original-html");
        if (originalHtml) {
          $link.html(originalHtml);
          $link.removeData("cap-original-html");
        }
        $link.prop("disabled", false);
        $link.removeAttr("disabled");
        $link.removeAttr("aria-busy");
        $link.removeClass("disabled");
      }
    },

    filenameFromUri: function (uri) {
      var parsed = new URL(uri, window.location.href);
      var filename = parsed.searchParams.get("filename");
      var slug = parsed.searchParams.get("slug");
      var pathname = parsed.pathname.split("/").pop();

      if (filename) {
        return filename;
      }
      if (slug) {
        return slug + ".pdf";
      }
      return pathname || "download";
    },

    triggerDownload: function (uri) {
      var deferred = $.Deferred();

      if (!uri) {
        deferred.reject();
        return deferred.promise();
      }

      var link = document.createElement("a");
      link.href = uri;
      link.download = downloads.filenameFromUri(uri);
      document.body.appendChild(link);
      link.click();
      link.remove();
      deferred.resolve();

      return deferred.promise();
    },

    openFresh: function (downloadUrl, unavailable, $link) {
      var deferred = $.Deferred();

      downloads.setLoading($link, true);
      downloads.fetchUri(downloadUrl).done(function (uri) {
        if (uri) {
          downloads.setLoading($link, false);
          downloads.setLink($link, uri);
          downloads.triggerDownload(uri);
          deferred.resolve();
        } else {
          downloads.setLoading($link, false);
          if (unavailable) {
            unavailable();
          }
          deferred.reject();
        }
      });

      return deferred.promise();
    },

    setupLink: function (link) {
      var $link = $(link);
      var downloadUrl = $link.attr("data-download-url");

      downloads.setLink($link, null);
      downloads.resolveUri(downloadUrl).done(function (uri) {
        downloads.setLink($link, uri);
      });

      $link.on("click", function (event) {
        event.preventDefault();
        if ($link.hasClass("disabled") || $link.prop("disabled")) {
          return;
        }

        downloads.openFresh(
          downloadUrl,
          function () {
            downloads.setLink($link, null);
          },
          $link
        );
      });
    },
  };

  window.capSignedDownloads = downloads;
})(window.jQuery);
