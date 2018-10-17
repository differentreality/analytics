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
    # @result[:data] = @post.reactions.group(:name).count
    @result[:data] = @post.reactions.map{ |r| [r.name, r.count] }.to_h
  end

  def make_graph
    #TODO rename @result to @graph
    @result = { data: [], graph_type: params[:graph_type] || 'column_chart'}
    # @result[:data] = @post.reactions.group(:name).count
    @result[:data] = @post.reactions.map{ |r| [r.name, r.count] }.to_h

    respond_to do |format|
      format.html
      format.js { render 'shared/make_graph'}
    end
  end
end
