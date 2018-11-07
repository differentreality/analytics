$(function () {
  $(document).ready(function() {
    if ( $.fn.dataTable.isDataTable( '.datatable' ) ) {
      table = $('.datatable').DataTable();
    }
    else {
      table = $('.datatable').DataTable( {
        destroy: true,
        autoWidth: false,
        bInfo: false,
        aaSorting: [[0, 'desc']],
        responsive: true,
        pagingType: 'full_numbers',
        lengthMenu: [[12, 24, 50, 100, -1], [12, 24, 50, 100, 'Όλα']],
      });
    }

    // Focus on search box
    $('div.dataTables_filter input').first().focus();
  });
});
