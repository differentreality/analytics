require 'rufus-scheduler'

scheduler = Rufus::Scheduler.singleton
@access_token = ENV['access_token']
@page_id = ENV['facebook_page_id']
@connection = Koala::Facebook::API.new(@access_token)
#
# run at 3am of next day
# scheduler.cron '00 03 * * *' do
scheduler.in '2s' do
  ## Refresh values from facebook
  # me/insights/page_fans
  # @result = @graph.get_connections(@page_id, "insights/page_fans")
  puts "in scheduler"
  facebook_connections('feed')
  facebook_connections('insights/page_fans')
end

def facebook_connections(field)
  puts "field: #{field}"
  result = @connection.get_connections(@page_id, field)
  # page = Page.find_by(object_id: @page_id)
  puts "result: #{result}"
  # return result.first['values'].first['value']
end
