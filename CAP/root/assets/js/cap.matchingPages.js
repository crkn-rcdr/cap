/* cap.matchingPages.js */

!(function($) {
    var MatchingPages = function(element) {
        this.init(element);
    }

    MatchingPages.prototype = {
        constructor: MatchingPages,

        init: function(element) {
            this.$element = $(element);
            this.$searching = $('.matching-pages-searching', this.$element);
            this.$results = $('.matching-pages-results', this.$element);
            var key = this.$element.attr('data-key');
            this.initialCallUrl = ['', 'search', 'matching_pages_initial', key].join('/');
            this.remainingCallUrl = ['', 'search', 'matching_pages_remaining', key].join('/');
            this.params = { q: this.$element.attr('data-q'), tx: this.$element.attr('data-tx'), fmt: 'ajax' };
            if (!!this.params.q || !!this.params.tx) {
                this.$searching.show();
                this.initialCall();
            }

            var $keywordSearch = $('#keywordSearch');
            if ($keywordSearch.length) {
                $keywordSearch.on('submit', $.proxy(this.submitSearch, this));
            }

            var $pvToolbar = $('#pvToolbar');
            if ($pvToolbar.length) {
                var pageViewer = $pvToolbar.data().pageViewer;
                this.$element.on('click', '.matching-page', function(e) {
                    e.preventDefault();
                    pageViewer.goToPage(parseInt($(this).attr('data-seq'), 10));
                })
            }
        },

        submitSearch: function(e) {
            e.preventDefault();
            this.params.q = $('input[name="q"]', $('#keywordSearch')).val();
            this.params.tx = "";
            if (!!this.params.q) {
                this.$results.empty();
                this.$searching.show();
                this.initialCall();
            }
        },

        initialCall: function() {
            var that = this;
            $.ajax({
                url: this.initialCallUrl,
                dataType: 'html',
                data: this.params,
                success: $.proxy(this.initialSuccess, this),
                error: function(data) {
                    that.$element.empty();
                    that.$element.html("Error &mdash; Erreur");
                }
            });
        },

        initialSuccess: function(data) {
            this.$searching.hide();
            this.$results.html(data);
            this.$remLoading = $('.matching-pages-loading', this.$element);
            this.$remLink = $('.matching-pages-remaining-link', this.$element);
            this.$remLoading.hide();
            this.$remLink.removeAttr('href');
            this.$remLink.on('click', $.proxy(this.getRemaining, this));
        },

        getRemaining: function(e) {
            e.preventDefault();
            this.$remLink.hide();
            this.$remLoading.show();
            this.params.rows = parseInt(this.$remLink.attr('data-rows'), 10);
            var that = this;
            var $rem = $('.matching-pages-remaining', that.$element);
            $.ajax({
                url: this.remainingCallUrl,
                dataType: 'html',
                data: this.params,
                success: function(data) {
                    $rem.empty();
                    $rem.html(data);
                },
                error: function(data) {
                    $rem.empty();
                    $rem.html("Error &mdash; Erreur");
                }
            }); 
        }
    };

    $.fn.matchingPages = function(option) {
        return this.each(function() {
            var $this = $(this);
            var data = $this.data('matchingPages');
            if (!data) { $this.data('matchingPages', (data = new MatchingPages(this))); }
            if (typeof option == 'string') { data[option](); }
        });
    };

    $.fn.matchingPages.Constructor = MatchingPages;
}(window.jQuery));
