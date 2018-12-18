class PostsController < ApplicationController
  skip_before_action :verify_authenticity_token, only: :webhook_notification
  load_resource only: [:show, :make_graph]
  load_resource :page, find_by: :object_id

  def index
    @posts = @page.posts
    @posts = @posts.send(params[:kind]) if params[:kind]

    @trending_graph_type = 'pie_chart'
    @trending_graph_data = {}
    @trending_graph_data[:all] = ApplicationController.helpers.posts_reactions_graph_data(@page, nil)
    Post.kinds.keys.each do |kind|
      @trending_graph_data[kind.to_sym] = ApplicationController.helpers.posts_reactions_graph_data(@page, kind)
    end
  end

  def trending_graph
    @page ||= Page.default
    @trending_graph_type = params[:graph_type]
    @kind = params[:kind]
    @category = params[:category]
    @trending_graph_data = {}
    @trending_graph_data[@kind.to_sym] = ApplicationController.helpers.posts_reactions_graph_data(@page, @kind)
  end

  def show
    #TODO rename @result to @graph
    @result = { data: { simple: [], multiple: [] }, graph_type: params[:graph_type] || 'column_chart'}
    @result[:data][:simple] = @post.reactions.group(:name).count
  end

  # Initialize posts
  def new
    result = []
    return unless @page.present?

    facebook_data = connection_result('get_connections',
                                      "#{@page.object_id}/posts",
                                      '?fields=message, type, created_time, story',
                                      @page.pages_users.find_by(user: current_user).access_token)
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
