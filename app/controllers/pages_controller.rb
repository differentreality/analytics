class PagesController < ApplicationController
  skip_before_action :verify_authenticity_token, only: :webhook_notification
  load_resource find_by: :object_id

  def index
    @data = {}
    @data[:multiple] = []
    @data[:simple] = {}
    @data[:simple][:data] = []

    redirect_to root_path and return unless current_user

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
      format.js { render 'home/make_graph'}
    end
  end
end
