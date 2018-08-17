$(function () {
  $('.dropdown-toggle').dropdown();

  $("input[id='days-datepicker']").datepicker({
      useCurrent: false,
      sideBySide: true,
      showButtonPanel: true,
      autoclose: true,
      language: "el",
      format: 'yyyy-mm-dd',
      startView: 0,
      todayBtn: true,
      orientation: "bottom auto"
  });

  $("input[id^='datepicker']").datepicker({
      useCurrent: false,
      sideBySide: true,
      showButtonPanel: true,
      autoclose: true,
      language: "el",
      format: 'yyyy-mm-dd',
      endDate: (new Date()).toISOString().substring(0, 10),
      startView: 1,
      todayBtn: true
  });

  $("input[id^='reverse-datepicker']").datepicker({
      useCurrent: false,
      sideBySide: true,
      showButtonPanel: true,
      autoclose: true,
      language: "el",
      format: 'yyyy-mm-dd',
      startView: 1,
      todayBtn: true
  });

  $("input[id^='notes_datepicker']").datepicker({
      startView: 1,
      minViewMode: 1,
      useCurrent: false,
      sideBySide: true,
      showButtonPanel: true,
      autoclose: true,
      language: "el",
      format: 'yyyy-mm',
      endDate: (new Date()).toISOString().substring(0, 10),
      orientation: "bottom auto"
  });

  $("input[id^='productions_datepicker']").datepicker({
      startView: 1,
      minViewMode: 1,
      useCurrent: false,
      sideBySide: true,
      showButtonPanel: true,
      autoclose: true,
      language: "el",
      format: 'yyyy-mm',
      endDate: (new Date()).toISOString().substring(0, 10)
  });

  $("input[id^='invoices_datepicker']").datepicker({
    startView: 1,
    minViewMode: 1,
    useCurrent: false,
    sideBySide: true,
    showButtonPanel: true,
    autoclose: true,
    language: "el",
    format: 'yyyy-mm',
      endDate: (new Date()).toISOString().substring(0, 10)
  });

  $(document).ready(function() {
    $('.datepicker-pay').datepicker({
      useCurrent: false,
      sideBySide: true,
      showButtonPanel: true,
      autoclose: true,
      language: 'el',
      format: 'yyyy-mm-dd',
        endDate: (new Date()).toISOString().substring(0, 10)
    }).on('changeDate', function(ev) {
      var date = ev.date;
      var model = $(this).attr('model');
      var model_path = $(this).attr('model_path');
      var record_id = $(this).attr(model + "_id");
      var company = $(this).attr('company');
      var data = "{ \"" + model + "\"" + ": { \"paid\": \"" + date + "\"} }";

      var url = '/companies/' + company + '/' + model_path + '/' + record_id;

      $.ajax({
        url: url,
        type: 'PATCH',
        data: JSON.parse(data),
        dataType: 'script'
      });
    });
  });
});
