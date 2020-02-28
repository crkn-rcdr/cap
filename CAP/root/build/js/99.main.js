$(function() {
  var action = location.pathname.split("/")[1];
  if (action === "search") {
    sessionStorage.setItem("query", $("#query").attr("value"));
    sessionStorage.setItem("searchPath", location.href);
  } else if (action === "view") {
    var query = sessionStorage.getItem("query");
    if (query) {
      $("#query").attr("value", query);
      $(".matching-pages").attr("data-query", query);
    }

    var searchPath = sessionStorage.getItem("searchPath");
    if (searchPath) {
      $("#searchBackButton").removeClass("hidden");
      $("#searchBackButton").attr("href", searchPath);
    }
  }

  var $indexTitle = $(".action-index #headerTitle");
  $(".menu-open").on("click", function(ev) {
    $("header").addClass("overlay");
    if ($indexTitle.length) {
      $indexTitle.attr(
        "src",
        $indexTitle.attr("src").replace("white", "color")
      );
    }
  });

  $(".menu-close").on("click", function(ev) {
    $("header").removeClass("overlay");
    if ($indexTitle.length) {
      $indexTitle.attr(
        "src",
        $indexTitle.attr("src").replace("color", "white")
      );
    }
  });

  $("#pvToolbar").pageViewer();
  $(".matching-pages").matchingPages();

  $(function() {
    $('[data-toggle="tooltip"]').tooltip();
  });

  $(".plus-minus").on("click", function(ev) {
    var $element = $(this);
    $element.text($element.text() === "+" ? "-" : "+");
  });
});
