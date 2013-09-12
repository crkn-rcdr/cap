/* cap.browse.js || CURRENTLY INACTIVE */

!(function($) {
    var Browse = function(element) {
        this.init(element);
    }

    $.fn.populate_browse = function(terms) {
        var $this = $(this);
        if (!$this.children().size()) {
            $('<li>Loading</li>').appendTo($this);
            var id = $this.attr('data-id');
            var url = ['', 'browse', id].join('/');
            $.ajax({
                url: url,
                data: { fmt: 'ajax' },
                datatype: 'json',
                success: function(data) {
                    $this.empty();
                    $.each($.parseJSON(data), function(index, obj) {
                        var $entry = $('<li></li>');
                        $entry.appendTo($this);
                        var $link = $('<a>' + obj.term + '</a>');
                        if (obj.url) {
                            if ($.inArray(obj.id, terms) !== -1) {
                                $link = $('<strong>' + obj.term + '</strong>');
                            } else {
                                $link.attr('href', obj.url);
                            }
                        } else {
                            $link.attr('data-toggle', 'collapse');
                            $link.attr('data-parent', '#' + $this.attr('id'));
                            //$link.attr('href', '#browse' + obj.id);
                            $link.attr('data-target', '#browse' + obj.id);
                            var $sublist = $('<ul></ul>');
                            $sublist.attr('class', 'browse collapse');
                            $sublist.attr('id', 'browse' + obj.id);
                            $sublist.attr('data-id', obj.id);
                            $sublist.appendTo($entry);
                            if ($.inArray(obj.id, terms) !== -1) { $sublist.collapse('show'); }
                        }
                        $link.prependTo($entry);
                    });
                },
                error: function(data) {

                }                
            });
        }
        return $this;
    }

    Browse.prototype = {
        constructor: Browse,

        init: function(element) {
            this.$element = $(element);
            var dataTerms = this.$element.attr('data-terms');
            var terms = dataTerms ? dataTerms.split(',') : [];
            $('.browse', element).populate_browse(terms);
            this.$element.on('show', '.browse', function(event) { $(event.target).populate_browse(terms); });
        }
    };

    $.fn.browse = function(option) {
        return this.each(function() {
            var $this = $(this);
            var data = $this.data('browse');
            if (!data) { $this.data('browse', (data = new Browse(this))); }
            if (typeof option == 'string') { data[option](); }
        });
    };

    $.fn.browse.Constructor = Browse;
}(window.jQuery));
