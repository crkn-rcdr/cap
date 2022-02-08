$(function () {
  var action = location.pathname.split("/")[1];
  if (action === "search") {
    sessionStorage.setItem("query", $("#query").attr("value"));
  } else if (action === "view") {
    var query = sessionStorage.getItem("query");
    if (query) {
      $("#query").attr("value", query);
      $(".matching-pages").attr("data-query", query);
    }
  }
  if (action === "browse") {
    sessionStorage.removeItem("query");
  }

  var $indexTitle = $(".action-index #headerTitle");
  $(".menu-open").on("click", function (ev) {
    $("header").addClass("overlay");
    if ($indexTitle.length) {
      $indexTitle.attr(
        "src",
        $indexTitle.attr("src").replace("white", "color")
      );
    }
  });

  $(".menu-close").on("click", function (ev) {
    $("header").removeClass("overlay");
    if ($indexTitle.length) {
      $indexTitle.attr(
        "src",
        $indexTitle.attr("src").replace("color", "white")
      );
    }
  });

  var $toolbar = $("#pvToolbar");
  if ($toolbar.attr("data-mode") === "noid") {
    $toolbar.dragonViewer();
  } else {
    $toolbar.pageViewer();
  }

  $(".matching-pages").matchingPages();

  $(function () {
    $('[data-toggle="tooltip"]').tooltip();
    $("#pvHelp").on("click", function (ev) {
      $("#pvToolbar *").tooltip("toggle");
      $("#pvHelp").toggleClass("active");
    });
  });

  $('[data-toggle="collapse"]').on("focusin", function (ev) {
    var $collapseTarget = $($(ev.target).attr("data-target"));
    $(document).on("keydown.cap", function (ev) {
      if (ev.key === "Enter" || ev.key === " " || ev.key === "Spacebar") {
        ev.preventDefault();
        $collapseTarget.collapse("toggle");
      }
    });
  });

  $('[data-toggle="collapse"').on("focusout", function (ev) {
    $(document).off("keydown.cap");
  });

  $(".plus-minus").on("click", function (ev) {
    var $element = $(this);
    var $expand = $element.children(".expand");
    var $collapse = $element.children(".unexpand");
    if ($expand.hasClass("hidden")) {
      $expand.removeClass("hidden");
      $collapse.addClass("hidden");
    } else {
      $expand.addClass("hidden");
      $collapse.removeClass("hidden");
    }
  });
});
