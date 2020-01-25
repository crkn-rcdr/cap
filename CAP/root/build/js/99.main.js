$(function() {
  // page viewer
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
