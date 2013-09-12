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

    var lang = $('html').attr('lang');
    $('table.table-data.contributors').dataTable({
        "bPaginate": false,
        "bLengthChange": false,
        "bFilter": true,
        "bSort": false,
        "bInfo": false,
        "bAutoWidth": false,
        "oLanguage": (lang === 'fr' ? {
            "sSearch": 'Rechercher&nbsp;:',
            "sZeroRecords": "Aucun &eacute;l&eacute;ment &agrave; afficher",
            "sEmptyTable": "Aucune donnée disponible dans le tableau",
        } : {
            "sZeroRecords": "No matching records found",
            "sEmptyTable": "No data available in table",
            "sSearch": "Search:",
        }),
    });
});
