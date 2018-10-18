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
    @result = { data: [], graph_type: params[:graph_type] || 'column_chart'}
    @result[:data] = @post.reactions.group(:name).count
  end

  def make_graph
    #TODO rename @result to @graph
    @result = { data: [], graph_type: params[:graph_type] || 'column_chart'}
    if params[:graph_type] == 'multiple_series'
      @result[:data] = []

      Reaction::KINDS.each do |reaction|
        @result[:data] << { name: reaction, data: @post.reactions.send(reaction).group_by_day(:posted_at).count }
      end
    else
      @result[:data] = @post.reactions.group(:name).count
    end

    respond_to do |format|
      format.html
      format.js { render 'shared/make_graph'}
    end
  end
end
