class HomeController < ApplicationController
  include ApplicationHelper
  skip_before_action :verify_authenticity_token, only: :webhook_notification
  load_resource :page, find_by: :object_id

  def reactions_graph
    @reactions_group_parameter = params[:group_parameter]
    @kind = params[:kind]
    @category = params[:category]
    @group_format = params[:group_format]
    @trending_graph_type = params[:trending_graph_type]
    @data = {}
    @data = ApplicationController.helpers.reactions_groupped(group_parameter: @reactions_group_parameter,
                                                             group_format: @group_format,
                                                             count: 'average')
  end

  def activity_graph
    @reactions_group_parameter = params[:group_parameter]
    @kind = params[:kind]
    @category = params[:category]
    @group_format = params[:group_format]
    @trending_graph_type = params[:graph_type]
    @graph_id = 'activity_average_chart'
    @data = {}
    @data = ApplicationController.helpers.reactions_groupped(group_parameter: @reactions_group_parameter,
                                                             group_format: @group_format,
                                                             count: 'average')
  end
end
