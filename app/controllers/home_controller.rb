class HomeController < ApplicationController
  include ApplicationHelper
  skip_before_action :verify_authenticity_token, only: :webhook_notification

  def make_graph
    @result = { data: [], graph_type: params[:graph_type]}

    # @result = @graph.get_connections(@page_id, "feed")
    # me/posts?fields=message,created_time, reactions

    # me/insights/page_fans
    # @result = @graph.get_connections(@page_id, "insights/page_fans")
    # @result = @connection.get_object("#{@page_id}/posts", { fields: 'created_time' })

    # posts?fields=insights.metric(post_reactions_by_type_total).period(lifetime).as(post_reactions_by_type_total)

    fields = '?fields=created_time,id, reactions.type(LIKE).limit(0).summary(1).as(like),reactions.type(LOVE).limit(0).summary(1).as(love),reactions.type(HAHA).limit(0).summary(1).as(haha),reactions.type(WOW).limit(0).summary(1).as(wow),reactions.type(SAD).limit(0).summary(1).as(sad),reactions.type(ANGRY).limit(0).summary(1).as(angry)'

    object = params[:x_axis]
    period = params[:y_axis]
    from = Date.parse(params[:from]) if params[:from].present?
    to = Date.parse(params[:to]) if params[:from].present?
    if object == 'all'
      ['posts', 'events', 'reactions'].each do |obj|
        @result[:data] << { name: obj, data: get_data(obj, period, from, to) }
      end
    else
      @result[:data] = get_data(object, period, from, to) if object && period
    end
    respond_to do |format|
      format.html { render template: 'home/index'
                  }
      format.js { render 'shared/make_graph' }
    end
  end

  def index
    @page_title = @page.try(:name) || get_page_title || 'Lambda Space'
    @page_fans_count = @page.try(:fans) || get_page_fans
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
    @result = { data: get_data('posts', period, from, to), graph_type: 'doughnut_chart' }

    @trending_graph_type = 'pie_chart'
    @trending_graph_data = {}
    @trending_graph_data[:all] = ApplicationController.helpers.posts_reactions_graph_data(nil)
    Post.kinds.keys.each do |kind|
      @trending_graph_data[kind.to_sym] = ApplicationController.helpers.posts_reactions_graph_data(kind)
    end
  end

  def trending_graph
    @trending_graph_type = params[:graph_type]
    @kind = params[:kind]
    @trending_graph_data = {}
    @trending_graph_data[@kind.to_sym] = ApplicationController.helpers.posts_reactions_graph_data(@kind)

    puts @trending_graph_data
  end

  def update_overall_statistics_table
    set_overall_result(params[:from], params[:to])

    respond_to do |format|
      format.js
    end
  end
end
