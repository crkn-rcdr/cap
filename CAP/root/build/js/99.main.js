$(function() {
  var action = location.pathname.split("/")[1];
  if (action === "search") {
    sessionStorage.setItem("query", $("#query").attr("value"));
    sessionStorage.setItem("searchPath", location.href);
  } else if (action === "view") {
    $("#query").attr("value", sessionStorage.getItem("query"));
    $(".matching-pages").attr("data-query", sessionStorage.getItem("query"));
    $("#searchBackButton").removeClass("hidden");
    $("#searchBackButton").attr("href", sessionStorage.getItem("searchPath"));
  }

  var $fancyTitle = $(".fancy.index #headerTitle");
  $(".menu-open").on("click", function(ev) {
    $("header").addClass("overlay");
    $(".fancy.index .above-fold").css("margin-top", "-1rem");
    if ($fancyTitle.length) {
      $fancyTitle.attr(
        "src",
        $fancyTitle.attr("src").replace("white", "color")
      );
    }
  });

  $(".menu-close").on("click", function(ev) {
    $("header").removeClass("overlay");
    $(".fancy.index .above-fold").css("margin-top", "calc(-240px - 1rem)");
    if ($fancyTitle.length) {
      $fancyTitle.attr(
        "src",
        $fancyTitle.attr("src").replace("color", "white")
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
