class ApplicationController < ActionController::Base
  # Prevent CSRF attacks by raising an exception.
  protect_from_forgery with: :exception

  # For APIs, you may want to use :null_session instead.
  before_action :save_return_to
  load_resource :page, find_by: :object_id

  def credentials(access_token=nil)
    unless access_token
      object_id = params[:page_id] || params[:id]
      page = @page || Page.find_by(object_id: object_id) || Page.default
      return unless page

      unless current_user
        access_token = page.pages_users.first.access_token
      end
      access_token ||= page.pages_users.find_by(user: current_user).access_token

      return unless access_token
    end

    @connection = Koala::Facebook::API.new(access_token)
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

    object_query = if object == 'page_fans'
                     'insights/page_fans'
                   else
                     object
                   end

    result = connection_result('get_object',
                               "#{@page.object_id}/#{object_query}",
                               { fields: fields,
                                 since: since_datetime,
                                 until: until_datetime })

    next_page = result.next_page
    while next_page.present?
      next_page.map{ |x| result << x }
      next_page = next_page.next_page
    end

    if object == 'page_fans'
      previous_page = result.previous_page
      while  previous_page.present?
        previous_page.map{ |x| result << x }
        previous_page = previous_page.previous_page
      end
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

  ##
  # Ajax call to update a chart
  def make_graph
    @reactions_group_parameter = params[:group_parameter]
    @kind = params[:kind]
    @category = params[:category]
    @group_format = params[:group_format]
    @trending_graph_type = params[:graph_type]
    @graph_id = params[:graph_id]
    @data = {}
    @data = ApplicationController.helpers.reactions_groupped(group_parameter: @reactions_group_parameter,
                                                             group_format: @group_format,
                                                             count: 'average')
    respond_to do |format|
      format.js { render 'shared/make_graph' }
    end
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
        @result_overall[object.to_sym][:all][period.to_sym][:values] = {}
        @result_overall[object.to_sym][:all][period.to_sym][:min] = {}
        @result_overall[object.to_sym][:all][period.to_sym][:max] = {}

        next unless object.to_s.classify.constantize.any?

        @result_overall[object.to_sym][:all][period.to_sym][:values] = get_data(@page, object.to_s, period.to_s, from, to)[:simple]

        @result_overall[object.to_sym][:all][period.to_sym][:max] = @result_overall[object.to_sym][:all][period.to_sym][:values].select{ |k, v| v == @result_overall[object.to_sym][:all][period.to_sym][:values].values.max }

        @result_overall[object.to_sym][:all][period.to_sym][:min] = @result_overall[object.to_sym][:all][period.to_sym][:values].select{ |k, v| v == @result_overall[object.to_sym][:all][period.to_sym][:values].values.min }
      end
    end

    Post.kinds.keys.each do |post_kind|
      @result_overall[:posts][post_kind.to_sym] = {}

      [:hour, :day, :month, :year].each do |period|
        @result_overall[:posts][post_kind.to_sym][period.to_sym] = {}
        @result_overall[:posts][post_kind.to_sym][period.to_sym][:values] = {}
        @result_overall[:posts][post_kind.to_sym][period.to_sym][:min] = {}
        @result_overall[:posts][post_kind.to_sym][period.to_sym][:max] = {}

        next unless Post.send(post_kind).any?

        @result_overall[:posts][post_kind.to_sym][period.to_sym][:values] = get_data(@page, 'post', period.to_s, from, to, post_kind)[:simple]

        @result_overall[:posts][post_kind.to_sym][period.to_sym][:max] =
        @result_overall[:posts][post_kind.to_sym][period.to_sym][:values].select{ |k, v| v == @result_overall[:posts][post_kind.to_sym][period.to_sym][:values].values.max }

        @result_overall[:posts][post_kind.to_sym][period.to_sym][:min] =
        @result_overall[:posts][post_kind.to_sym][period.to_sym][:values].select{ |k, v| v == @result_overall[:posts][post_kind.to_sym][period.to_sym][:values].values.min }
      end
    end
  end

  ##
  # Get a set of records, attribute and group parameter
  # Return hash of hashes with the count for all age groups
  # Count is of male or female fans (attribute_value)
  # ==== Returns
  # * +Hash+ --> { '13-17' => 1,
  #                '18-24' => 3
  #              }
  def fans_group(records, attribute, attribute_value, group_param)
    result = @page.age_fans
    result = result.where(attribute.to_sym => attribute_value) if attribute
    result = result.group_by{ |info| info.send(group_param) }
                   .collect{ |groupping, records| max_date = records.max_by{ |r| r.date }.date;
                                             [ groupping, records.select{ |r| r.date == max_date }.sum(&:count) ] }.to_h

    return result
  end

  # === Returns
  # * +Hash+ -> period and count
  # period can be hour, day, month, year, eg.
  # { "02"=>1, "04"=>1, "05"=>2, "06"=>5 }
  # { "Sunday"=>11, "Monday"=>38, "Tuesday"=>51, "Wednesday"=>37, "Thursday"=>34, "Friday"=>22, "Saturday"=>17 }
  # { "January"=>19, "February"=>27, "March"=>31 }
  # { "2016"=>32, "2017"=>88, "2018"=>90 }
  def get_data(page, object, period, from=nil, to=nil, kind=nil, insights: false)
    result = {}
    period_symbol = datetime_symbol(period)
    redirect_to root_path && return unless page.present? && object.present? && period.present?

    result_initial = page&.send(object.pluralize) || []
    result_initial = result_initial.send(kind) if kind
    result_initial = result_initial.where('posted_at >= ?', from) if from.present?
    result_initial = result_initial.where('posted_at <= ?', to) if to.present?


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
    result[:simple] = result_initial.map{ |x| x.posted_at.to_s if x.posted_at }.
                                     compact.
                                     group_by{ |x| x.to_datetime&.strftime(period_symbol) }.
                                     map{ |k, v| [k,v.count] }.to_h

    sort_by = case period_symbol
              when '%B'
                Date::MONTHNAMES
              when '%A'
                Date::DAYNAMES
              else
                nil
              end

    result[:simple] = if sort_by
                        result[:simple].sort_by{ |k,v| [sort_by.find_index(k), v]}.to_h
                      else
                        result[:simple].sort.to_h
                      end

    multiple_diversifier = case object
                           when 'posts'
                             'kind'
                           when 'reactions'
                             'name'
                           end

    # [{ name: 'haha', data: { }}]
    result[:multiple] = []
    if multiple_diversifier
      result[:multiple] << { name: 'all',
                             data: result[:simple] }

      result[:multiple] = result_initial.
                          group_by(&multiple_diversifier.to_sym).
                          map{ |kind, data| { name: kind, data: data.map{ |x| x.posted_at.to_s if x.posted_at }.
                          compact.group_by{ |x| x.to_datetime&.strftime(period_symbol) }.
                          map{ |k, v| [k,v.count] }.
                          to_h  } }
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

  def facebook_data_all_pages(result)
    next_page = result.next_page
    while next_page.present?
      next_page.map{ |x| result << x }
      next_page = next_page.next_page
    end

    return result
  end

  def connection_result(method, object, params=nil, access_token=nil)
    credentials(access_token)
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
    return unless @page
    credentials
    @result = begin
                @connection.get_object(@page.object_id)
              rescue => e
                Rails.logger.debug "Could not retrieve data from Facebook. #{e.message}"
                nil
              end
    return @result['name'] if @result.present?
  end

  def get_page_fans
    return unless @page
    credentials
    @result = begin
                @connection.get_connections(@page.object_id, "insights/page_fans")
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
