# frozen_string_literal: true

namespace :reactions do
  desc 'Initialize reactions data'

  task posts: :environment do
    puts 'Get reactions for existing posts'
    result = []
    fields = '?fields=created_time,reactions.type(LIKE).limit(0).summary(1).as(like),reactions.type(LOVE).limit(0).summary(1).as(love),reactions.type(HAHA).limit(0).summary(1).as(haha),reactions.type(WOW).limit(0).summary(1).as(wow),reactions.type(SAD).limit(0).summary(1).as(sad),reactions.type(ANGRY).limit(0).summary(1).as(angry)'

    access_token = ENV['access_token']
    page_id = ENV['facebook_page_id']
    connection = Koala::Facebook::API.new(access_token)

    connection_result = connection.get_connections("#{page_id}/posts", fields)
    puts "connection_result: #{connection_result}"
    connection_result.map{ |x| result << x }

    # Loop data to get everything
    next_page = connection_result.next_page
    while next_page.present?
      next_page.map{ |x| result << x }
      next_page = next_page.next_page
      puts "next_page: #{next_page}"
    end

    # Save result to database
    result_db_items = []
    result.each do |result_item|
      post = Post.find_by(object_id: result_item['id'])
      reactions = result_item.keys.select{ |r| r == 'like' || r == 'love' || r == 'haha' || r == 'wow' || r == 'sad' || r == 'angry'}

      reactions.each do |reaction|
        reaction_count = result_item[reaction]['summary']['total_count'].to_i
        db_objects = Reaction.where(reactionable: post, name: reaction)

        unless db_objects && db_objects.length == reaction_count
          times = reaction_count - db_objects.length
          times.times do
            db_object = Reaction.new(reactionable: post,
                                     name: reaction,
                                     posted_at: Date.current)
            if db_object.save
              result_db_items << db_object
            else
              Rails.logger.info "Could not save new item: #{db_object.inspect}. Errors: #{db_object.errors.full_messages.to_sentence}"
            end
          end
        end
      end
    end
    puts 'All done!'
    puts "Created #{result_db_items.count} items"
  end
end
