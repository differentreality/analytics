$(document).ready(function() {
  $('select#chart_graph_type').change( function() {
    var kind = $(this).find('option:selected').data('kind');
    var graph_type = $(this).find('option:selected').val();
    var graph_data = $('#chart_graph_data_status').val();

    $.ajax({
      type: 'POST',
      url: '/trending_graph',
      data: { graph_type: graph_type,
              kind: kind },
      dataType: 'script'
    });
  });
});

$('select#graph_type').change( function() {
  var url = "#{make_graph_path}";
  var x_axis = $('#x_axis option:selected').val();
  var y_axis = $('#y_axis option:selected').val();
  var graph_type = $('#graph_type option:selected').val();

  if (x_axis != '' && y_axis !='') {
    $.ajax({
      type: 'POST',
      url: '/make_graph',
      data: { graph_type: graph_type, x_axis: x_axis, y_axis: y_axis },
      dataType: 'script'
    });
  }
});
