/* cap.preloader.js */
!(function( $ ) {
    $.extend({
        preloadImages: function(uris) {
            var $cache = $('#imageCache');
            if (!$cache.length) {
                $('body').append('<div id="imageCache"></div>');
            }

            $.map(uris, function(uri) {
                $cache.append('<img src="' + uri + '" />');
            });
        }
    });
}( window.jQuery ));
