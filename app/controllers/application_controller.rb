class ApplicationController < ActionController::Base
  # Prevent CSRF attacks by raising an exception.
  protect_from_forgery with: :exception

  # For APIs, you may want to use :null_session instead.
  before_action :save_return_to
  load_resource :page, find_by: :object_id

  rescue_from CanCan::AccessDenied do |exception|
    Rails.logger.debug "Access denied on #{exception.action} #{exception.subject.inspect}"
    redirect_to root_path, alert: exception.message
  end

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

    object_query = if object == 'fans'
                     'insights/page_fans'
                   elsif object == 'city_fans'
                     'insights/page_fans_city'
                   elsif object == 'age_fans'
                     'insights/page_fans_gender_age'
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

    if object == 'fans'
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
  # Set the color for reaction kinds
  def reactions_chart_colors
    ['#337ab7', '#ffc0cb', '#3c763d', '#8a6d3b', '#31708f', '#a94442', 'fff']
  end

  def make_overall_graph_time_periods
    object = params[:x_axis]
    period = params[:y_axis]
    time_periods = params[:time_periods]
    graph_type = params[:graph_type]

    if params[:x_axis] == 'reactions'
      @colors = reactions_chart_colors
    end

    respond_to do |format|
      format.js { render 'shared/overall_graph' }
      format.html { redirect_to page_path(@page,
                                          time_periods: time_periods,
                                          object: object,
                                          graph_type: graph_type,
                                          period: period) }
    end
  end

  ##
  # Set @result variable for the overall graph
  # @result = { simple: [], multiple: [] , graph_type: params[:graph_type] || 'column_chart'}
  # @result[:data][:simple] = @page.reactions.group(:name).count
  def make_overall_graph
    # TODO sort returned hash (eg. overall chart group day of month for all)
    object = params[:x_axis]
    period = params[:y_axis]
    from = params[:from]
    to = params[:to]
    graph_type = params[:graph_type]

    if params[:x_axis] == 'reactions'
      @colors = reactions_chart_colors
    end

    @result = { simple: [], multiple: [], graph_type: graph_type || 'column_chart'}

    if object == 'all'
      ['posts', 'events', 'reactions'].each do |obj|
        data = get_data(@page, obj, period, from, to)
        @result[:multiple] << { name: obj, data: data[:simple] }
      end
    else
      data = get_data(@page, object, period, from, to)
      @result[:simple] = data[:simple]

      kinds = case object
              when 'posts'
                Post.kinds.keys
              when 'reactions'
                Reaction::KINDS
              end
      kinds&.each do |kind|
        @result[:multiple] << { name: kind, data: get_data(@page, object, period, from, to, kind)[:simple] }
      end

      unless @result[:multiple].any?
        @result[:multiple] << { name: object, data: data }
      end
    end

    respond_to do |format|
      format.js { render 'shared/overall_graph' }
      format.html { redirect_to page_path(@page) }
    end
  end

  ##
  # Ajax call to update a chart
  def make_graph
    @reactions_group_parameter = params[:group_parameter] || params[:y_axis]
    @kind = params[:kind]
    @category = params[:category]
    @group_format = params[:group_format]
    @trending_graph_type = params[:graph_type]
    @graph_type = @trending_graph_type
    @chart_id = params[:graph_id] || 'overall-chart'
    if (params[:x_axis] == 'reactions') || (params[:category] == 'reactions')
      @colors = reactions_chart_colors
    end
    @data = {}
    @data = ApplicationController.helpers.reactions_groupped(@page,
                                                             group_parameter: @reactions_group_parameter,
                                                             group_format: @group_format,
                                                             count: 'average')
    respond_to do |format|
      format.js { render 'shared/make_graph' }
    end
  end

  def yearly_content
    Rails.logger.debug "page: #{@page.inspect} and params: #{params[:page_id]}"
    @graph_type = params[:graph_type]
    @chart_id = params[:chart_id]
    set_yearly_content
    @result = @yearly_content

    respond_to do |format|
      format.html
      format.js { render 'shared/make_graph'}
    end
  end

  def set_yearly_content
    set_overall_result

    @yearly_content = {}
    @yearly_content[:simple] = []
    @yearly_content[:multiple] = []

    @result_overall[:posts].each do |kind_values|
      @yearly_content[:multiple] << { name: kind_values.first.capitalize,
                                      data: kind_values.second[:year][:values] }
    end

    @yearly_content[:simple] << @yearly_content[:multiple].select{ |h| h[:name] == :All}.first[:data]
  end

  def update_overall_statistics_table
    set_overall_result(params[:from], params[:to])

    respond_to do |format|
      format.js { render 'pages/update_overall_statistics_table' }
    end
  end

  ##
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
  def set_overall_result(from=nil, to=nil)
    return { } unless @page.present?

    @result_overall = {}
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

  def fans_group_location(group_param: 'country', country: nil)
    records = @page.city_fans.all
    records = records.where(country: country) if country
    records.group_by{ |info| info.send(group_param) }.collect{ |groupping, records| max_date = records.max_by{|r| r.date}.date; [ groupping, records.select{ |r| r.date == max_date  }.sum(&:count) ] }.to_h
  end

  ##
  # Creates graph data for fans per age and gender
  # groupping parameter is either age or city
  # ==== Returns
  # * +Hash+ --> { simple: {},
  #                multiple: {}
  #              }
  def fans_graph_data(groupping)
    @result = { simple: {}, multiple: [] }

    if groupping == 'age'
      records = @page.age_fans
      @result[:simple] = fans_group(records, nil, nil, 'age_range')
      @result[:multiple] << { name: 'All', data: fans_group(records, nil, nil, 'age_range')}

      AgeFan.genders.each do |gender_key, gender_value|
        data = fans_group(records, 'gender', gender_value, 'age_range')
        @result[:multiple] << { name: gender_key, data: data }
      end

    elsif groupping == 'city'
      @result[:simple] = fans_group_location(group_param: 'municipality')

      countries = @page.city_fans.pluck(:country).uniq

      countries.each do |country|
        @result[:multiple] << { name: country,
                                data: fans_group_location(group_param: 'municipality', country: country)}
      end

    elsif groupping == 'country'
      @result[:simple] = fans_group_location(group_param: 'country')
    end

    return @result
  end

  ##
  # Gets a hash and sorts it
  # ==== Gets
  # hash to be sorted, and optionally a period_symbol
  # ==== Returns
  # * +Hash+ -> hash sorted
  def hash_sort(data_hash, period_symbol=nil)
    sort_by = case period_symbol
              when '%B'
                Date::MONTHNAMES
              when '%A'
                Date::DAYNAMES
              when '%H'
                ['01', '02', '03', '04', '05', '06', '07', '08', '09', '10',
                 '11', '12', '13', '14', '15', '16', '17', '18', '19', '20',
                 '21', '22', '23', '00']
              else
                nil
              end

    if sort_by
      sort_by.compact.each do |sort_value|
        data_hash[sort_value.to_s] = data_hash.fetch(sort_value.to_s, 0)
      end


      data_hash.map{ |result_item| result_item[:data] = sort_by.compact.each do |sort_value|
                                                      result_item[:data].fetch(sort_value.to_s, 0)
                                                    end
                } if data_hash.keys.include?(:data)
    end

    data_hash = if sort_by
             data_hash.sort_by{ |k,v| [sort_by.find_index(k), v]}.to_h
           else
             data_hash.sort.to_h
           end

    return data_hash
  end

  # === Returns
  # * +Hash+ -> period and count
  # period can be hour, day, month, year, eg.
  # { "02"=>1, "04"=>1, "05"=>2, "06"=>5 }
  # { "Sunday"=>11, "Monday"=>38, "Tuesday"=>51, "Wednesday"=>37, "Thursday"=>34, "Friday"=>22, "Saturday"=>17 }
  # { "January"=>19, "February"=>27, "March"=>31 }
  # { "2016"=>32, "2017"=>88, "2018"=>90 }
  def get_data(page, object, period, from=nil, to=nil, kind=nil, insights: false)
    # Initialize variables
    result = {}
    result[:simple] = []
    result[:multiple] = []
    period_symbol = datetime_symbol(period)
    redirect_to root_path && return unless page.present? && object.present? && period.present?

    # Initialize data according to parameters
    result_initial = page&.send(object.pluralize) || []
    result_initial = result_initial.send(kind) if kind
    result_initial = result_initial.where('posted_at >= ?', from) if from.present?
    result_initial = result_initial.where('posted_at <= ?', to) if to.present?

    result[:simple] = result_initial.map{ |x| x.posted_at.to_s if x.posted_at }.
                                     compact.
                                     group_by{ |x| x.to_datetime&.strftime(period_symbol) }.
                                     map{ |k, v| [k,v.count] }.to_h

    result[:simple] = hash_sort(result[:simple], period_symbol)

    multiple_diversifier = case object
                           when 'posts'
                             'kind'
                           when 'reactions'
                             'name'
                           end

    result[:multiple] = []
    if multiple_diversifier
      result[:multiple] = result_initial.
                          group_by(&multiple_diversifier.to_sym).
                          map{ |kind, data| { name: kind,
                                              data: data.map{ |x| x.posted_at.to_s if x.posted_at }.
                                                        compact.
                                                        group_by{ |x| x.to_datetime&.strftime(period_symbol) }.
                                                        map{ |k, v| [k,v.count] }.
                                                        to_h
                                            }
                              }
      result[:multiple] << { name: 'All',
                             data: result[:simple] }
    end

    if result[:multiple].any?
      result[:multiple].map!{ |result_item| { name: result_item[:name],
                                              data: hash_sort(result_item[:data], period_symbol) } }
    end

    return result
  end

  ##
  # Returns data groupped by categories (kinds of posts, kinds of reactions)
  # It is assumed that the time restriction is already known, and applied elsewhere
  # We collect time period information only to filter the records
  # ==== Returns
  # * +Hash+ -> { }
  # result in get_data_reverse: {:simple=>{"link"=>0, "status"=>0, "photo"=>0, "video"=>0, "offer"=>0, "event"=>0, "note"=>0}, :multiple=>[]}
  # result: {:data=>[{:simple=>{}, :multiple=>[{:name=>"period1", :data=>{"status"=>4, "photo"=>3, "link"=>3, "video"=>1}}, {:name=>"period2", :data=>{"link"=>0, "status"=>0, "photo"=>0, "video"=>0, "offer"=>0, "event"=>0, "note"=>0}}]}], :graph_type=>"multiple_series_column_chart", :colors=>["#5b90bf", "#96b5b4", "#adc896", "#ab7967", "#d08770", "#b48ead"]}
  #
  #
  #  period1_data: {:simple=>{"status"=>4, "photo"=>3, "link"=>3, "video"=>1}, :multiple=>[{:name=>"link", :data=>{"January"=>0, "February"=>0, "March"=>0, "April"=>0, "May"=>0, "June"=>2, "July"=>1, "August"=>0, "September"=>0, "October"=>0, "November"=>0, "December"=>0}}, {:name=>"status", :data=>{"January"=>0, "February"=>0, "March"=>0, "April"=>0, "May"=>0, "June"=>2, "July"=>2, "August"=>0, "September"=>0, "October"=>0, "November"=>0, "December"=>0}}, {:name=>"photo", :data=>{"January"=>0, "February"=>0, "March"=>0, "April"=>0, "May"=>0, "June"=>3, "July"=>0, "August"=>0, "September"=>0, "October"=>0, "November"=>0, "December"=>0}}, {:name=>"video", :data=>{"January"=>0, "February"=>0, "March"=>0, "April"=>0, "May"=>0, "June"=>1, "July"=>0, "August"=>0, "September"=>0, "October"=>0, "November"=>0, "December"=>0}}]}

  # No need for result[:multiple][:all] because we are in time periods
  # we call this method inside the time_periods loop
  # for each iteration, we only need 1 result in result[:multiple]

  def get_data_reverse(page, object, period, from=nil, to=nil, kind=nil, insights: false)
    # Initialize variables
    result = {}
    result[:simple] = []
    result[:multiple] = []
    period_symbol = datetime_symbol(period)
    redirect_to root_path && return unless page.present? && object.present? && period.present?

    # Initialize data according to parameters
    result_initial = page&.send(object.pluralize) || []
    result_initial = result_initial.send(kind) if kind
    result_initial = result_initial.where('posted_at >= ?', from) if from.present?
    result_initial = result_initial.where('posted_at <= ?', to) if to.present?

    unless result[:simple].any?
      result[:simple] = Post.kinds.collect{ |kind| [kind.first, 0] }.to_h
    end
    # result[:simple] = hash_sort(result[:simple], period_symbol)

    # result[:multiple] = result_initial.group(:kind).count
    # result[:multiple][:all] = result_initial.count

    multiple_diversifier = case object
                           when 'posts'
                             'kind'
                           when 'reactions'
                             'name'
                           end

    if multiple_diversifier
      result[:multiple] = result_initial.group(multiple_diversifier.to_sym).count
    end

    #   result_initial.group(multiple_diversifier.to_sym).count.each do |kind, count|
    #     result[:multiple] << { name: kind,
    #                            data: count }
    #   end
    #
    #   result[:multiple] << { name: 'all',
    #                          data: result[:simple] }
    #
    #
    # end

    # if result[:multiple].any?
    #   result[:multiple].map!{ |result_item| { name: result_item[:name],
    #                                           data: hash_sort(result_item[:data], period_symbol) } }
    # end
    return result
  end

  def values_for_analytics_option
    @values = YAML::load(ENV['object_options'])

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
      next_page = next_page&.next_page
    end

    return result
  end

  def connection_result(method, object, params=nil, access_token=nil)
    credentials(access_token)
    @result = begin
                if method == 'get_object'
                  @connection.get_object(object, params)
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
             when 'day_of_month'
               '%d'
             when 'week'
               '%W'
             when 'month'
               '%B'
             when 'year'
               '%Y'
             when 'hour'
               '%H'
             end
    return result
  end
end
