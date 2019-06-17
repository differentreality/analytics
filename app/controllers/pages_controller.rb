class PagesController < ApplicationController
  skip_before_action :verify_authenticity_token, only: :webhook_notification
  load_and_authorize_resource find_by: :object_id

  def index
    @data = {}
    @data[:multiple] = []
    @data[:simple] = {}
    @data[:simple][:data] = []

    @page ||= Page.default

    redirect_to page_path(@page) and return unless current_user

    current_user.pages.each do |page|
      @data[:multiple] << { name: page.name,
                            data: page.posts.group(:kind).count }
    end
  end

  def trending_graph
    @trending_graph_type = params[:graph_type]
    @kind = params[:kind]
    @category = params[:category]
    @trending_graph_data = {}
    @trending_graph_data[@kind.to_sym] = ApplicationController.helpers.posts_reactions_graph_data(@page, @kind)
  end

  def show
    @posts = @page.posts.all
    @posts = @posts.send(params[:kind]) if params[:kind]

    # Load fan data first, because the functions used also set @result variable
    # Here we want the @result variable overriden
    @country_fans = fans_graph_data('country')
    @city_fans = fans_graph_data('city')
    @age_fans = fans_graph_data('age')

    @trending_graph_type = 'pie_chart'
    @trending_graph_data = {}
    @trending_graph_data[:all] = ApplicationController.helpers.posts_reactions_graph_data(@page, nil)
    Post.kinds.keys.each do |kind|
      @trending_graph_data[kind.to_sym] = ApplicationController.helpers.posts_reactions_graph_data(@page, kind)
    end

    @page_title = @page.try(:name) || get_page_title || 'Lambda Space'
    @page_fans_count = @page.try(:fans) || get_page_fans
    @result = {}

    # Sets variable @result_overall in ApplicationController for Activity tab
    set_overall_result

    # Sets variable @yearly_content for Activity tab
    set_yearly_content

    # Initial data for overall chart
    # unless already defined (readirected with params from make_overall_graph)
    # used for reverse charts
    if params[:graph_type]
      @time_periods = params[:time_periods]
      object = params[:object]
      period = params[:period]
      @graph_type = params[:graph_type]

      @result = { data: { simple: [], multiple: [] }, graph_type: @graph_type }

      @time_periods.each do |time_period|
        @result[:data][:multiple] << { name: "#{time_period[:from].to_s.tr('-', '.')} - #{time_period[:to].to_s.tr('-', '.')}",
                                       data: get_data_reverse(@page,
                                                              object,
                                                              period,
                                                              time_period[:from],
                                                              time_period[:to])[:multiple] }
        # @result[:data][:multiple] << { name: 'All', data: get_data_reverse(@page,
        #                                                                    object,
        #                                                                    period,
        #                                                                    time_period[:from],
        #                                                                    time_period[:to])[:count]}

      end

    else
      # Initial data for chart
      @from = Date.new(Date.current.year - 1)
      @to = Date.new(Date.current.year - 1).end_of_year
      period = 'month'
      @result = { data: get_data(@page, 'posts', period, @from, @to) }

      #
      # # Create a hash for each time period item
      # period1_from = Date.new(2017, 01, 01)
      # period1_to = Date.new(2017, 12, 31)
      # period2_from = Date.new(2016, 01, 01)
      # period2_to = Date.new(2016, 12, 31)
      # period1_data = get_data_reverse(@page, 'posts', period, period1_from, period1_to )
      # period2_data = get_data_reverse(@page, 'posts', period, period2_from, period2_to )
      # @time_periods = [ { from: period1_from, to: period1_to },
      #                   { from: period2_from, to: period2_to }]
      #
      # data = {}
      # data[:simple] = {}
      # data[:multiple] = [ { name: "#{period1_from.to_s.tr('-', '.')} - #{period1_to.to_s.tr('-', '.')}",
      #                       data: period1_data[:simple] },
      #                     { name: "#{period2_from.to_s.tr('-', '.')} - #{period2_to.to_s.tr('-', '.')}",
      #                       data: period2_data[:simple] } ]
      #
      # @result = { data: data,
      #             graph_type: 'multiple_series_column_chart',
      #             colors: ['#5b90bf', '#96b5b4', '#adc896', '#ab7967', '#d08770', '#b48ead'] }
    end
  end

  # Initialize posts
  def new
    result = []
    return unless @page.present?

    facebook_data = connection_result('get_connections',
                                      "#{@page.object_id}/posts",
                                      '?fields=message, type, created_time, story')
    result = facebook_data_all_pages(facebook_data) if facebook_data
    # Save posts to database
    result_db_items = []
    result.each do |result_item|
      db_object = Post.find_by(object_id: result_item['id'])
      if db_object.present?
        next
      end
      db_object = Post.new(object_id: result_item['id'],
                           kind: (result_item['type']&.to_sym),
                           message: result_item['message'],
                           story: result_item['story'],
                           posted_at: result_item['created_time'])

      unless db_object.save
        Rails.logger.info "Could not save new item: #{db_object.inspect}\n errors: #{db_object.errors.full_messages.to_sentence}"
        next
      end
      result_db_items << db_object
    end
    redirect_to root_path
  end

  def make_graph
    #TODO rename @result to @graph
    @result = { data: { simple: [], multiple: [] }, graph_type: params[:graph_type] || 'column_chart'}

    if params[:graph_type] == 'multiple_series'
      Reaction::KINDS.each do |reaction|
        @result[:data][:multiple] << { name: reaction, data: @post.reactions.send(reaction).group_by_day(:posted_at).count }
      end
    else
      @result[:data][:simple] = @post.reactions.group(:name).count
    end

    respond_to do |format|
      format.html
      format.js { render 'shared/make_graph'}
    end
  end
end
