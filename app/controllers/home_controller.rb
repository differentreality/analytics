class HomeController < ApplicationController
  include ApplicationHelper
  skip_before_action :verify_authenticity_token, only: :webhook_notification
  load_resource :page, find_by: :object_id

  def make_graph
    @result = { data: [], graph_type: params[:graph_type]}

    # @result = @graph.get_connections(@page.object_id, "feed")
    # me/posts?fields=message,created_time, reactions

    # me/insights/page_fans
    # @result = @graph.get_connections(@page.object_id, "insights/page_fans")
    # @result = @connection.get_object("#{@page.object_id}/posts", { fields: 'created_time' })

    # posts?fields=insights.metric(post_reactions_by_type_total).period(lifetime).as(post_reactions_by_type_total)

    fields = '?fields=created_time,id, reactions.type(LIKE).limit(0).summary(1).as(like),reactions.type(LOVE).limit(0).summary(1).as(love),reactions.type(HAHA).limit(0).summary(1).as(haha),reactions.type(WOW).limit(0).summary(1).as(wow),reactions.type(SAD).limit(0).summary(1).as(sad),reactions.type(ANGRY).limit(0).summary(1).as(angry)'

    object = params[:x_axis]
    period = params[:y_axis]
    from = Date.parse(params[:from]) if params[:from].present?
    to = Date.parse(params[:to]) if params[:from].present?
    if object == 'all'
      @result[:data] = {}
      @result[:data][:multiple] = []

      ['posts', 'events', 'reactions'].each do |obj|
        data = get_data(@page, obj, period, from, to)
        @result[:data][:multiple] << { name: obj, data: data[:simple] }
      end
    else
      @result[:data] = get_data(@page, object, period, from, to) if object && period
    end
    respond_to do |format|
      format.html { render template: 'home/index'
                  }
      format.js { render 'home/make_graph' }
    end
  end

  def index
    @page = @page || Page.default #TODO make this the default selected page

    if current_user
      redirect_to pages_path
    end
    @page_title = @page.try(:name)
    @page_fans_count = @page.try(:fans)
    @result = {}

    set_overall_result

    @yearly_content = []

    @result_overall[:posts].each do |kind_values|
      @yearly_content << { name: kind_values.first.capitalize,
                           data: kind_values.second[:year][:values] }
    end

    # Initial data for chart
    from = Time.current - 3.months
    to = Time.current
    period = 'month'
    @result = { data: get_data(@page, 'posts', period, from, to), graph_type: 'doughnut_chart' }
    @trending_graph_type = 'pie_chart'
    @trending_graph_data = {}
    @trending_graph_data[:all] = ApplicationController.helpers.posts_reactions_graph_data(@page, nil)
    Post.kinds.keys.each do |kind|
      @trending_graph_data[kind.to_sym] = ApplicationController.helpers.posts_reactions_graph_data(@page, kind)
    end

    @reactions_groupped = {}
    @reactions_groupped[:all] = ApplicationController.helpers.reactions_groupped(group_format: @group_format)

    respond_to do |format|
      format.html# { render template: 'home/index'
                  #}
      format.js #{ render 'home/make_graph' }
    end
  end

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

  def update_overall_statistics_table
    set_overall_result(params[:from], params[:to])

    respond_to do |format|
      format.js
    end
  end
end
