$(function () {
  $('.dropdown-toggle').dropdown();

  $("input[id^='datepicker']").datepicker({
      useCurrent: false,
      pickTime: true,
      sideBySide: true,
      showButtonPanel: true,
      autoclose: true,
      language: 'en',
      format: 'yyyy-mm-dd',
      endDate: (new Date()).toISOString().substring(0, 10),
      startView: 1,
      todayBtn: true
  });
});
