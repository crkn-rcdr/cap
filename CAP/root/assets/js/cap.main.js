$(function () {
    // page viewer
    $('#pvToolbar').pageViewer();

    // placeholder polyfill
    $('input[placeholder], textarea[placeholder]').placeholder();

    $('.plus-minus').on('click', function (ev) {
        var $element = $(this);
        $element.text($element.text() === '+' ? '-' : '+');
    });

    var $collectionList = $('.collection-list');
    $('.collection-list li a').each(function () {
        var $this = $(this);
        var key = $this.data('collection');
        var $target = $('#' + key);
        $target.hide();
        $target.removeClass('hidden');
        $this.removeAttr('href');

        $this.on('click', function(ev) {
            $collectionList.fadeOut('fast', function() {
                $target.fadeIn('fast');
            });
        });
    });

    $('.ci-back').on('click', function(ev) {
        $(this).parent().parent().fadeOut('fast', function() {
            $collectionList.fadeIn('fast');
        });
    });

    $('.slideshow').slideshow();
    $('.collections').collections();
    $('.matching-pages').matchingPages();

    $('#feesTrigger').popover();

    $('.co #wrapper').append('<div class="bg"></div>');

    // terms of service checkbox validation
    var tosForm = $('form').has('input[name="terms"][type="checkbox"]');
    if (tosForm.length) {
        var tosBox = $("input:checkbox[name='terms']", tosForm);
        var tosButton = $("button:submit[data-blockterms='blockterms']", tosForm);
        if (!tosBox.attr("checked")) {
            tosButton.attr("disabled", "disabled");
        }
        tosBox.on('change', function(e) {
            tosBox.attr("checked") ? tosButton.removeAttr("disabled") : tosButton.attr("disabled", "disabled");
        });
    }

    $('table.table-data.user-list').dataTable({
        "sDom": "<'row'<'span6'l><'span6'f>r>t<'row'<'span6'i><'span6'p>>",
        "sPaginationType": "bootstrap",
        "oLanguage": {
            "sLengthMenu": "_MENU_ records per page"
        }
    });

    // load tab based on URL fragment
    // the replace handles cases where window.location.hash doesn't return the '#'
    var fragment = '#' + window.location.hash.replace('#','');
    $('.nav-tabs a[href="' + fragment + '"]').tab('show');

    // in a browse tree, replace any link to the current page's href with a strong non-link,
    // and open all of the collapsed branches containing said link
    var $browseContext = $('ul.browse');
    if ($browseContext.length) {
        var $link = $('[href="' + window.location.href + '"]', $browseContext);
        $link.parents('.collapse').addClass('in');
        $link.replaceWith('<strong>' + $link.text() + '</strong>');
    }
});
