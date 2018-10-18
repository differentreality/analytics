class ApplicationController < ActionController::Base
  # Prevent CSRF attacks by raising an exception.
  protect_from_forgery with: :exception
  before_action :credentials

  # For APIs, you may want to use :null_session instead.
  before_action :save_return_to

  def credentials
    @access_token = ENV['access_token']
    @page_id = ENV['facebook_page_id']
    @page = Page.find_by(object_id: @page_id)
    @connection = Koala::Facebook::API.new(@access_token)
  end

  def facebook_data
    result = []
    object = params[:object]
    since_datetime = params[:since_datetime]
    until_datetime = params[:until_datetime]
    fields = if object == 'posts'
               'message, type, created_time'
             elsif object == 'events'
               'name, start_time.as(created_time)'
             end

    result = connection_result('get_object',
                               "#{@page_id}/#{object}",
                               { fields: fields,
                                 since: since_datetime,
                                 until: until_datetime })

    next_page = result.next_page
    while next_page.present?
      next_page.map{ |x| result << x }
      next_page = next_page.next_page
    end

    # Save result to database
    result_db_items = []
    result.each do |result_item|
      db_object = object.classify.constantize.find_by(object_id: result_item['id'])
      if db_object.present?
        next
      end
      db_object = object.classify.constantize.new(object_id: result_item['id'],
                                                  posted_at: result_item['created_time'])
      if object == 'posts'
        db_object.message = result_item['message']
        db_object.kind = result_item['type']&.to_sym
      elsif object == 'events'
        db_object.name = result_item['name']
      end

      unless db_object.save
        Rails.logger.info "Could not save new item: #{db_object.inspect}\n errors: #{db_object.errors.full_messages.to_sentence}"
        next
      end
      result_db_items << db_object
    end

    redirect_to root_path
  end

  def set_overall_result(from=nil, to=nil)
    # Initialize overall statistic values
    # {
    #  :posts=>{ :year=> {:min=>{"2016"=>32},
    #                     :values=>{"2016"=>32, "2017"=>88, "2018"=>89},
    #                     :max=>{"2018"=>89}
    #                    },
    #            :month => {},
    #            :day => {},
    #            :hour => {}
    #          },
    #  :events=>{ :year=>{:min=>{"2016"=>10}, :values=>{"2016"=>10, "2017"=>28, "2018"=>23}, :max=>{"2017"=>28}}}
    # }

    # @posts_per_year = Post.all.group_by{ |post| post.}

    @result_overall = {}
    # = @result_posts[:year].select{ |k, v| v == @result_posts[:year].values.max }.to_a.join(' -> ')
    # [:posts, :events].each do |object|
    @result_overall[:posts] = {}

    [:posts, :events, :reactions].each do |object|
      @result_overall[object.to_sym] = {} unless @result_overall[object.to_sym]
      @result_overall[object.to_sym][:all] = {}

      [:hour, :day, :month, :year].each do |period|

        @result_overall[object.to_sym][:all][period.to_sym] = {}

        @result_overall[object.to_sym][:all][period.to_sym][:min] = {}

        @result_overall[object.to_sym][:all][period.to_sym][:values] = get_data(object.to_s, period.to_s, from, to)

        @result_overall[object.to_sym][:all][period.to_sym][:max] = @result_overall[object.to_sym][:all][period.to_sym][:values].select{ |k, v| v == @result_overall[object.to_sym][:all][period.to_sym][:values].values.max }

        @result_overall[object.to_sym][:all][period.to_sym][:min] = @result_overall[object.to_sym][:all][period.to_sym][:values].select{ |k, v| v == @result_overall[object.to_sym][:all][period.to_sym][:values].values.min }
      end
    end

    Post.kinds.keys.each do |post_kind|
      @result_overall[:posts][post_kind.to_sym] = {}
      [:hour, :day, :month, :year].each do |period|

        @result_overall[:posts][post_kind.to_sym][period.to_sym] = {}

        @result_overall[:posts][post_kind.to_sym][period.to_sym][:min] = {}

        @result_overall[:posts][post_kind.to_sym][period.to_sym][:values] = get_data('post', period.to_s, from, to, post_kind)

        @result_overall[:posts][post_kind.to_sym][period.to_sym][:max] =
        @result_overall[:posts][post_kind.to_sym][period.to_sym][:values].select{ |k, v| v == @result_overall[:posts][post_kind.to_sym][period.to_sym][:values].values.max }

        @result_overall[:posts][post_kind.to_sym][period.to_sym][:min] =
        @result_overall[:posts][post_kind.to_sym][period.to_sym][:values].select{ |k, v| v == @result_overall[:posts][post_kind.to_sym][period.to_sym][:values].values.min }
      end
    end
  end

  def get_data(object, period, from=nil, to=nil, kind=nil, insights: false)
    result = {}
    period_symbol = datetime_symbol(period)
    redirect_to root_path && return unless object.present? && period.present?

    result = object.classify.constantize.all
    result = result.send(kind) if kind
    result = result.where('posted_at >= ?', from) if from.present?
    result = result.where('posted_at <= ?', to) if to.present?

            # if object.classify.constantize.all.any?
            #   object.classify.constantize.all
            #   #  facebook_data(object, last_object.try(:posted_at).to_i, Time.now.to_i)
            #  else
            #    facebook_data(object)
            #  end
    # When NOT to call FB API ??
    # Renew items from different button??

    # from fb data
    # if period_symbol && result && result.any?
    #   result = result.map{ |x| x['created_time'].to_s }.group_by{ |x| x.to_datetime.strftime(period_symbol) }.map{ |k, v| [k,v.count]  }
    # end

    # from DB data
    result = result.map{ |x| x.posted_at.to_s if x.posted_at }.compact.group_by{ |x| x.to_datetime&.strftime(period_symbol) }.map{ |k, v| [k,v.count] }.to_h

    sort_by = case period_symbol
              when '%B'
                Date::MONTHNAMES
              when '%A'
                Date::DAYNAMES
              else
                nil
              end

    result = if sort_by
              result.sort_by{ |k,v| [sort_by.find_index(k), v]}.to_h
            else
              result.sort.to_h
            end

    return result
  end

  def values_for_analytics_option
    analytics_options_hash = YAML::load(ENV['analytics_options'])
    @values = analytics_options_hash[params['key']]

    respond_to do |format|
      format.js { render partial: 'shared/values_for_analytics_option' }
    end
  end

  def redirect_to_back_or(path)
    if request.env['HTTP_REFERER']
      redirect_to :back
    else
      redirect_to path
    end
  end

  def not_found
    raise ActionController::RoutingError.new('Not Found')
  end

  def connection_result(method, object, params=nil)
    @result = begin
                if method == 'get_object'
                  @connection.get_object(object)
                elsif method == 'get_connections'
                  @connection.get_connections(object, params)
                end
              rescue => e
                Rails.logger.debug "Could not retrieve data from Facebook. #{e.message}"
                nil
              end
    return @result
  end

  def get_page_title
    @result = begin
                @connection.get_object(@page_id)
              rescue => e
                Rails.logger.debug "Could not retrieve data from Facebook. #{e.message}"
                nil
              end
    return @result['name'] if @result.present?
  end

  def get_page_fans
    @result = begin
                @connection.get_connections(@page_id, "insights/page_fans")
              rescue => e
                Rails.logger.debug "Could not retrieve data from Facebook. #{e.message}"
                nil
              end

    return @result.first['values'].first['value'] if @result.present?
  end

  protected

  def save_return_to
    return unless request.get?
    if request.path != '/user/' && !request.xhr?
      session[:return_to] = request.fullpath
    end
  end

  def configure_permitted_parameters
    devise_parameter_sanitizer.permit(:account_update, keys: [:first_name, :last_name])
  end

  def datetime_symbol(text)
    result = case text
             when 'day'
               '%A'
             when 'month'
               '%B'
             when 'hour'
               '%H'
             when 'year'
               '%Y'
             end
    return result
  end
end
