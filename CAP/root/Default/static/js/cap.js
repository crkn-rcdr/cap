// Enable debugging to provide alerts when various transactions would
// otherwise silently fail.
var Debug = true;
var Interactive = true;

function debug(message) {
    if (Debug) {
        $("#Debug").css("visibility", "visible");
        $("#Debug").append(message + "\n");
    }
}

$(document).ready(function() {
   //search menu animations
   $('#btnContributors').click(function(){
     $('#ddownContributors').fadeToggle();
	 return false;
   });
   $('#btnAdvancedSearch').click(function () {
     $('#ddownAdvancedSearch').fadeToggle()
	 return false;
   }); 

    // Hide the search options by default and add a handler to toggle them
    // open/closed.
    $(".search_options").css("display", "none");
    $(".search_options_expand").click(function() {
        if($(".search_options").css("display") == "none") {
            $(".search_options").css("display", "block");
            $(".search_options_expand").css("background-image", 'url("' + CAP.icon_collapse + '")');
        }
        else {
            $(".search_options").css("display", "none");
            $(".search_options_expand").css("background-image", 'url("' + CAP.icon_expand + '")');
        }
    });

    debug("Debug mode enabled");
});

jQuery.fn.fadeToggle = function(speed, easing, callback) {
   return this.animate({opacity: 'toggle'}, speed, easing, callback);
};

