class ApplicationController < ActionController::Base
  # Prevent CSRF attacks by raising an exception.
  # For APIs, you may want to use :null_session instead.
  protect_from_forgery with: :exception
  before_action :credentials

  before_action :save_return_to

  def credentials
    @access_token = ENV['access_token']
    @page_id = ENV['facebook_page_id']
    @connection = Koala::Facebook::API.new(@access_token)
  end

  def facebook_data(object, since_datetime=nil, until_datetime=nil)
    result = []
    puts "object: #{object} \n since: #{since_datetime} \n until:#{until_datetime} \n"
    result = @connection.get_object("#{@page_id}/#{object}", { fields: 'message, type, created_time' })

    next_page = result.next_page
    while next_page.present?
      next_page.map{ |x| result << x }
      next_page = next_page.next_page
    end

    puts "result: #{result}"


    # Save result to database
    result.each do |result_item|
      db_object = object.classify.constantize.new(message: result_item['message'],
                                      kind: result_item['type'].to_sym,
                                      object_id: result_item['id'],
                                      posted_at: result_item['created_time'])
      unless db_object.save
        Rails.logger.info "Could not save new item: #{db_object.inspect}"
      end
    end
    return result
  end

  def get_data(object, period, insights: false)
    result = {}
    puts "object: #{object}, period: #{period}"

    period_symbol = datetime_symbol(period)
    puts "period_symbol: #{period_symbol}"

    result = if object.classify.constantize.all.any?
               last_object = object.classify.constantize.last
               facebook_data(object, last_object.try(:posted_at).to_i, Time.now.to_i)
             else
               facebook_data(object)
             end
    # When NOT to call FB API ??
    # Renew items from different button??

    puts "result before map: #{result}"
    # @result[:data] = [
    #   {"created_time"=>"2018-07-30T04:45:20+0000", "id"=>"295754757450351_291408578279339"},  {"created_time"=>"2018-05-02T16:40:47+0000", "id"=>"295754757450351_589995214692969"},
    #   {"created_time"=>"2018-04-25T20:02:24+0000", "id"=>"295754757450351_170162407029320"}, {"created_time"=>"2018-04-25T18:00:47+0000", "id"=>"295754757450351_586812398344584"}, {"created_time"=>"2016-09-09T11:28:00+0000", "id"=>"295754757450351_304858289873331"}
    # ]
    # since=1532120400

    if period_symbol && result && result.any?
      result = result.map{ |x| x['created_time'].to_s }.group_by{ |x| x.to_datetime.strftime(period_symbol) }.map{ |k, v| [k,v.count]  }
    end
  end

  def values_for_analytics_option
    analytics_options_hash = YAML::load(ENV['analytics_options'])
    @values = analytics_options_hash[params['key']]
    puts "@values: #{@values}, hash: #{analytics_options_hash}, values: #{analytics_options_hash['posts']}"

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

  def get_page_title
    @result = @connection.get_object(@page_id)
    return @result['name']
  end

  def get_page_fans
    @result = @connection.get_connections(@page_id, "insights/page_fans")
    return @result.first['values'].first['value']
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
             end
    return result
  end
end
