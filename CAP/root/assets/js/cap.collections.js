/* cap.collections.js */

!(function($) {
    var Collections = function(element) {
        this.init(element);
    }

    Collections.prototype = {
        constructor: Collections,

        init: function(element) {
            this.$links = $('.collections-header', element);
            this.$target = $('.collections-target', element);
            var collections = this;
            this.$links.click(function () {
                var $this = $(this);
                if (!$this.hasClass('selected')) {
                    var $content = $($this.attr('data-target'));
                    collections.$links.removeClass('selected');
                    $this.addClass('selected');
                    collections.$target.fadeOut('fast', function() {
                        collections.$target.children().remove();
                        collections.$target.append($content.html());
                        collections.$target.fadeIn('fast');
                    });
                }
            });
            if ($(window).width() >= 768) this.$links.first().click();
        }
    };

    $.fn.collections = function(option) {
        return this.each(function() {
            var $this = $(this);
            var data = $this.data('collections');
            if (!data) { $this.data('collections', (data = new Collections(this))); }
            if (typeof option == 'string') { data[option](); }
        });
    };

    $.fn.collections.Constructor = Collections;
}(window.jQuery));
