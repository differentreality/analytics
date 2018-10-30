class PostsController < ApplicationController
  skip_before_action :verify_authenticity_token, only: :webhook_notification
  load_resource only: [:show, :make_graph]

  def index
    @posts = Post.all
    @posts = @posts.send(params[:kind]) if params[:kind]
  end

  def show
    #TODO rename @result to @graph
    puts "result: #{@result.inspect}"
    @result = { data: { simple: [], multiple: [] }, graph_type: params[:graph_type] || 'column_chart'}
    @result[:data][:simple] = @post.reactions.group(:name).count
  end

  # Initialize posts
  def new
    result = []

    facebook_data = connection_result('get_connections',
                                      "#{@page_id}/posts",
                                      '?fields=message, type, created_time, story')
    puts "CHECK: #{facebook_data.first}"
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
