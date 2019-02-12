class EventsController < ApplicationController
  load_resource :page, find_by: :object_id

  def new
    # Call API to get ALL posts
    result = []

    facebook_data = connection_result('get_connections',
                                      "#{@page.object_id}/events",
                                      nil)
    result = facebook_data_all_pages(facebook_data) if facebook_data
    # Save posts to database
    result_db_items = []
    result.each do |result_item|
      db_object = @page.events.find_by(object_id: result_item['id'])
      if db_object.present?
        next
      end
      db_object = @page.events.new(object_id: result_item['id'],
                                   name: result_item['name'],
                                   posted_at: result_item['created_time'] || Time.current,
                                   start_time: result_item['start_time'],
                                   end_time: result_item['end_time'])

      unless db_object.save
        Rails.logger.info "Could not save new item: #{db_object.inspect}\n errors: #{db_object.errors.full_messages.to_sentence}"
        next
      end
      result_db_items << db_object
    end
    redirect_to :back
  end
end
