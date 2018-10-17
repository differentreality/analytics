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
