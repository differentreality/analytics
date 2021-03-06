$(document).ready(function() {

  $("form[id^='chart_form'] select").change( function() {
    group_parameter_selector = $("select[id$='group_parameter']");
    graph_type_selector = $("form[id^='chart_form'] select[id$='graph_type']");

    var category = group_parameter_selector.find('option:selected').data('category');
    var kind = group_parameter_selector.find('option:selected').data('kind');
    var group_parameter = group_parameter_selector.find('option:selected').data('group-parameter');
    var group_format = group_parameter_selector.find('option:selected').data('format');
    var graph_type = graph_type_selector.find('option:selected').val();
    var graph_id = $("[id$='graph_id']").val();
    var page_id = group_parameter_selector.find('option:selected').data('page-id');

    $.ajax({
      type: 'POST',
      url: '/make_graph',
      data: { group_parameter: group_parameter,
              kind: kind,
              page_id: page_id,
              category: category,
              group_format: group_format,
              graph_type: graph_type,
              graph_id: graph_id },
      dataType: 'script'
    });
  });

  $('select#chart_graph_type').change( function() {
    var kind = $(this).find('option:selected').data('kind');
    var category = $(this).find('option:selected').data('category');
    var graph_type = $(this).find('option:selected').val();
    var chart_id = $(this).find('option:selected').data('chart-id');
    var page_id = $(this).find('option:selected').data('page-id');

    $.ajax({
      type: 'POST',
      url: '/trending_graph',
      data: { graph_type: graph_type,
              kind: kind,
              chart_id: chart_id,
              category: category,
              page_id: page_id },
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
