$(function() {
  // page viewer
  $("#pvToolbar").pageViewer();
  $(".fulltext-tooltip").tooltip();
  $(".matching-pages").matchingPages();

  // placeholder polyfill
  $("input[placeholder], textarea[placeholder]").placeholder();

  $(".plus-minus").on("click", function(ev) {
    var $element = $(this);
    $element.text($element.text() === "+" ? "-" : "+");
  });
});
