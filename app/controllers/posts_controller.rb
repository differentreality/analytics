class PostsController < ApplicationController
  skip_before_action :verify_authenticity_token, only: :webhook_notification
  load_resource only: [:show, :make_graph]
  load_resource :page, find_by: :object_id

  def index
    @posts = @page.posts
    @kind = params[:kind]
    @posts = @posts.send(@kind) if @kind

    @posts_kind_distribution_data = { simple: @posts.group(:kind).count }

    page_logo_info = connection_result('get_connections',
                                        "#{@page.object_id}/",
                                        '?fields=picture')
    @logo_link = page_logo_info['picture']['data']['url'] if page_logo_info.present?

    @trending_graph_type = 'pie_chart'
    @trending_graph_data = {}
    @trending_graph_data[:all] = ApplicationController.helpers.posts_reactions_graph_data(@page, nil)
    @kinds = Post.kinds.keys
    @kinds.each do |kind|
      @trending_graph_data[kind.to_sym] = ApplicationController.helpers.posts_reactions_graph_data(@page, kind)
    end
    @result = {}
    @result[:graph_type] = 'pie_chart'
  end

  def trending_graph
    @page ||= Page.default
    # @trending_graph_type = params[:graph_type]
    @graph_type = params[:graph_type]
    @chart_id = params[:chart_id]
    @kind = params[:kind]
    @category = params[:category]
    @trending_graph_data = {}
    @trending_graph_data[@kind.to_sym] = ApplicationController.helpers.posts_reactions_graph_data(@page, @kind)

    render 'shared/make_graph'
  end

  def show
    @result = { simple: [], multiple: [], graph_type: params[:graph_type] || 'column_chart'}
    @result[:simple] = @post.reactions.group(:name).count
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
      db_object = @page.posts.find_by(object_id: result_item['id'])
      if db_object.present?
        next
      end

      db_object = @page.posts.new(object_id: result_item['id'],
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
    redirect_to :back
  end

  def make_graph
    #TODO rename @result to @graph
    @result = { simple: [], multiple: [], graph_type: params[:graph_type] || 'column_chart'}

    if params[:graph_type] == 'multiple_series_column_chart' || params[:graph_type] == 'multiple_series_line_chart'
      Reaction::KINDS.each do |reaction|
        @result[:multiple] << { name: reaction, data: @post.reactions.send(reaction).group_by_day(:posted_at).count }
      end
    else
      @result[:simple] = @post.reactions.group(:name).count
    end

    @chart_id = "post_#{@post.id}"
    @graph_type = params[:graph_type]

    respond_to do |format|
      format.html
      format.js { render 'shared/make_graph' }
    end
  end
end
