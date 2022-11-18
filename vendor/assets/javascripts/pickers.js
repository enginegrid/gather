(function() {
  // From https://github.com/zpaulovics/datetimepicker-rails
  function initPickers() {
    var defaultKeyBinds = $.fn.datetimepicker.defaults.keyBinds;
    delete defaultKeyBinds.t;
    $('.datetimepicker').datetimepicker({
      // put here your custom picker options, that should be applied for all pickers
      icons: {
        date: 'fa fa-calendar',
        time: 'fa fa-clock',
        up: 'fa fa-chevron-up',
        down: 'fa fa-chevron-down',
        previous: 'fa fa-chevron-left',
        next: 'fa fa-chevron-right',
        today: 'fa fa-crosshairs',
        clear: 'fa fa-trash',
        close: 'fa fa-times'
      },
      keyBinds: defaultKeyBinds
    });

    $('.datetimerange').each(function(){
      var $this = $(this)
      var range1 = $($this.find('.input-group')[0])
      var range2 = $($this.find('.input-group')[1])

      if(range1.data("DateTimePicker").date() != null)
        range2.data("DateTimePicker").minDate(range1.data("DateTimePicker").date());

      if(range2.data("DateTimePicker").date() != null)
        range1.data("DateTimePicker").maxDate(range2.data("DateTimePicker").date());

      range1.on("dp.change",function (e) {
        if(e.date)
          range2.data("DateTimePicker").minDate(e.date);
        else
          range2.data("DateTimePicker").minDate(false);
      });

      range2.on("dp.change",function (e) {
        if(e.date)
          range1.data("DateTimePicker").maxDate(e.date);
        else
          range1.data("DateTimePicker").maxDate(false);
      });
    })
  }

  // Run on document ready. We do it this way instead of how it is in the docs because
  // otherwise this function runs after all the $(doc).ready() stuff in the app, which is a problem.
  $(initPickers);

  // Also run on page change.
  $(document).on('page:change', initPickers);
})();
