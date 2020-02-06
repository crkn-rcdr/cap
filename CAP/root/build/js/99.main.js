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

  $("#menuButton").on("click", function(ev) {
    $("#menuOverlay").css("display", "block");
  });

  $("#menuClose").on("click", function(ev) {
    $("#menuOverlay").css("display", "none");
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
