/* cap.slideshow.js */

!(function($) {
    var Slideshow = function(element) {
        this.init(element);
    }

    Slideshow.prototype = {
        constructor: Slideshow,

        init: function(element) {
            this.$element = $(element);
            this.$window = $('.slideshow-window', this.$element);
            this.$gallery = $('.slideshow-gallery', this.$window);
            this.slides = this.$gallery.children();

            this.setGalleryWidth();
            this.setupControls();
            this.checkBounds();

            // reset gallery width on image load
            var slideshow = this;
            $('img', this.$gallery).load(function() {
                slideshow.setGalleryWidth();
                slideshow.checkBounds();
            });
        },

        setGalleryWidth: function() {
            var width = 0;
            this.slides.each(function() {
                var debugWidth = $(this).outerWidth(true);
                width += $(this).outerWidth(true);
            });
            this.$gallery.width(width + 4);
        },

        setupControls: function() {
            var slideshow = this;
            var control = function(selection, handler) {
                $(selection).removeAttr("href");
                return {
                    selector: $(selection),
                    enable: function() {
                        this.selector.removeClass('disabled');
                        if (!(this.selector.data('events') && this.selector.data('events')['click'])) {
                            this.selector.on('click.slideshow', $.proxy(handler, slideshow));
                        }
                    },
                    disable: function() {
                        this.selector.addClass('disabled');
                        this.selector.off('click.slideshow');
                    }
                };
            };

            this.leftnav = control('.slideshow-left-nav', this.clickLeft);
            this.rightnav = control('.slideshow-right-nav', this.clickRight);

            // dimensions change on window resize, check bounds again
            $(window).resize(function() { slideshow.checkBounds(); });
        },

        checkBounds: function() {
            var gwidth = this.$gallery.width();
            var wwidth = this.$window.width();
            var left = this.left();
            if (gwidth > wwidth) {
                if (left < 0) {
                    this.leftnav.enable();
                } else {
                    this.leftnav.disable();
                }
                if (gwidth > wwidth - left) {
                    this.rightnav.enable();
                } else {
                    this.rightnav.disable();
                    this.$gallery.css('left', '' + (wwidth - gwidth) + 'px');
                }
            } else {
                this.leftnav.disable();
                this.rightnav.disable();
                this.$gallery.css('left', '0px');
            }
        },

        clickLeft: function() {
            this.move("+=", this.left() * -1);
        },

        clickRight: function() {
            this.move("-=", this.$gallery.width() + this.left() - this.$window.width());
        },

        move: function(operation, boundary) {
            var slideshow = this;
            slideshow.leftnav.enable();
            slideshow.rightnav.enable();
            var shift = Math.min(boundary, 200);
            slideshow.$gallery.stop().animate(
                { "left": operation + shift + "px" },
                shift * 3,
                "linear",
                function() {
                    slideshow.checkBounds();
                }
            );
        },

        left: function() {
            return parseInt(this.$gallery.css("left"), 10);
        }
    };

    $.fn.slideshow = function(option) {
        return this.each(function() {
            var $this = $(this);
            var data = $this.data('slideshow');
            if (!data) { $this.data('slideshow', (data = new Slideshow(this))); }
            if (typeof option == 'string') { data[option](); }
        });
    };

    $.fn.slideshow.Constructor = Slideshow;
}(window.jQuery));
