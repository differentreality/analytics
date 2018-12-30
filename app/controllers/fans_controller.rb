class FansController < ApplicationController
  load_resource :page, find_by: :object_id

  def age
    result = collect_data("#{@page.object_id}/insights/page_fans_gender_age")

    # Create DB records
    result.each do |result_item|
      result_item['values'].first['value'].each do |gender_age, count|
        keys_split = gender_age.split('.').collect(&:strip)
        gender = case keys_split.first
                 when 'F'
                   0
                 when 'M'
                   1
                 when 'U'
                   2
                 end

        db_object = @page.age_fans.where(gender: gender,
                                         age_range: keys_split.second,
                                         date: result_item['values'].first['end_time']).find_or_create_by(count: count)
      end
    end

    redirect_to :back
  end

  def city
    result = collect_data("#{@page.object_id}/insights/page_fans_city")

    unless result
      flash[:error] = 'Could not retrieve information from Facebook.'
      redirect_to page_path(@page) and return
    end

    # Create DB records
    result.each do |result_item|
      result_item['values'].first['value'].each do |city_info, count|
        keys_split = city_info.split(',').collect(&:strip)

        db_object = @page.city_fans.where(country: keys_split.last,
                                          province: keys_split.second,
                                          municipality: keys_split.first,
                                          date: result_item['values'].first['end_time']).find_or_create_by(count: count)
      end
    end

    redirect_to :back
  end

  def renew_age_fans
    @result = { data: { } }
    @result[:data][:multiple] = []
    # @result = { data: [], graph_type: params[:graph_type]}

    @result[:data][:simple] = { data: fans_group(@page.age_fans, nil, nil, 'age_range') }
    @result[:data][:multiple] << { name: 'all', data: fans_group(@page.age_fans, nil, nil, 'age_range') }

    AgeFan.genders.each do |gender_key, gender_value|
      data = fans_group(@page.age_fans, 'gender', gender_value, 'age_range')
      @result[:data][:multiple] << { name: gender_key, data: data }
    end

    @graph_type = params[:graph_type]
    @graph_id = 'demographics_age'

    respond_to do |format|
      format.js { render 'home/make_graph' }
    end
  end

  def destroy
  end

  private
    def collect_data(object)
      result = connection_result('get_object', object, { since: Time.new(2017, 11, 22).to_i,
                                                         until: Time.new(2017, 11, 24).to_i })
      if result
        begin
          latest_result = result

          earliest_date = result.last['values'].last['end_time'] if result
          latest_date = result.last['values'].last['end_time'] if result

          # Grab all previous pages
          previous_page = latest_result&.previous_page
          while previous_page.present?
            earliest_date = previous_page.last['values'].last['end_time']
            previous_page.map{ |x| result << x }
            previous_page = previous_page.previous_page
          end

        rescue => e
          Rails.logger.debug "ERROR: #{e.message}"
          latest_result = connection_result('get_object',
                                            "#{@page.object_id}/insights/page_fans_city", { until: earliest_date.to_i })
          retry
        end

        # Grab all next pages
        begin
          next_page = latest_result.next_page
          while next_page.present?
            latest_date = next_page.last['values'].last['end_time']
            next_page.map{ |x| result << x }
            next_page = next_page.next_page
          end
        rescue Koala::Facebook::APIError => e
          Rails.logger.debug "ERROR: #{e.message}"
          latest_result = connection_result('get_object',
                                            "#{@page.object_id}/insights/page_fans_city", { since: latest_date.to_i })
          retry
        end

        return result
      end
    end
end
