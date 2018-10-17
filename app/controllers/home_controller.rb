class HomeController < ApplicationController
  skip_before_action :verify_authenticity_token, only: :webhook_notification

  def make_graph
    @result = { data: [], graph_type: params[:graph_type]}

    # Koala.config.api_version = "v2.0"
    # @graph.get_object("me", {}, api_version: "v2.0")
    # @result = @graph.get_connections(@page_id, "feed")
    # me/posts?fields=message, created_time,reactions

    # me/insights/page_fans
    # @result = @graph.get_connections(@page_id, "insights/page_fans")

    # me/posts?fields=created_time
    # Returns array of hashes
    # @result = @connection.get_object("#{@page_id}/posts", { fields: 'created_time' })
    #
    # next_page = @result.next_page
    # while next_page.present?
    #   @result << next_page
    #   next_page.map{ |x| @result << x}
    #   next_page = next_page.next_page
    # end
    # @result[:data] = [
    #   {"created_time"=>"2018-07-30T04:45:20+0000", "id"=>"295754757450351_291408578279339"},  {"created_time"=>"2018-05-02T16:40:47+0000", "id"=>"295754757450351_589995214692969"},
    #   {"created_time"=>"2018-04-25T20:02:24+0000", "id"=>"295754757450351_170162407029320"}, {"created_time"=>"2018-04-25T18:00:47+0000", "id"=>"295754757450351_586812398344584"}, {"created_time"=>"2016-09-09T11:28:00+0000", "id"=>"295754757450351_304858289873331"}
    # ]
    # puts "result: #{@result.first['created_time'].to_datetime.strftime('%A')}"
    # @result[:data] = @result[:data].map{ |x| x['created_time'].to_s }.group_by{ |x| x.to_datetime.strftime('%A') }.map{ |k, v| [k,v.count]  }


    # posts?fields=insights.metric(post_reactions_by_type_total).period(lifetime).as(post_reactions_by_type_total)
    test_result = []
    # result = connection_result('get_object', "#{@page_id}/#{object}", { fields: fields, since: since_datetime, until: until_datetime })

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

    # test_result = connection_result('get_connections', "#{@page_id}/posts", { fields: fields } )
    # test_result = @connection.get_connections("#{@page_id}/videos", fields)
    # puts "test_result: #{test_result}"

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
  end

  def update_overall_statistics_table
    set_overall_result(params[:from], params[:to])

    respond_to do |format|
      format.js
    end
  end

  def max_reactions
    # me/posts?fields=created_time,story,message,shares,reactions.type(LIKE).limit(0).summary(1).as(like),reactions.type(LOVE).limit(0).summary(1).as(love),reactions.type(HAHA).limit(0).summary(1).as(haha),reactions.type(WOW).limit(0).summary(1).as(wow),reactions.type(SAD).limit(0).summary(1).as(sad),reactions.type(ANGRY).limit(0).summary(1).as(angry)
  end
end
