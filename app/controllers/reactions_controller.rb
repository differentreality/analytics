class ReactionsController < ApplicationController
  load_resource :page, find_by: :object_id

  def new
    result = []
    fields = '?fields=created_time,
    reactions.type(LIKE).limit(0).summary(1).as(like), reactions.type(LOVE).limit(0).summary(1).as(love),
    reactions.type(HAHA).limit(0).summary(1).as(haha), reactions.type(WOW).limit(0).summary(1).as(wow),
    reactions.type(SAD).limit(0).summary(1).as(sad), reactions.type(ANGRY).limit(0).summary(1).as(angry)'

    # Result:
    # [  { "created_time"=>"2018-09-24T13:41:35+0000",
    #      "like"=>{  "data"=>[],
    #                 "summary"=>{"total_count"=>4, "viewer_reaction"=>"NONE"} },
    #      "love"=>{  "data"=>[],
    #                 "summary"=>{"total_count"=>0, "viewer_reaction"=>"NONE"} },
    #      "id"=>"295754757450351_700138760345280"},
    #    {} ]

    facebook_data = connection_result('get_connections',
                                      "#{@page.object_id}/posts",
                                      fields)

    result = facebook_data_all_pages(facebook_data) if facebook_data

    # Save posts to database
    result_db_items = []
    result.each do |result_item|
      post = @page.posts.find_by(object_id: result_item['id'])
      next unless post
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
            unless db_object.save
              Rails.logger.info "Could not save new item: #{db_object.inspect}. Errors: #{db_object.errors.full_messages.to_sentence}"
              next
            end
            result_db_items << db_object
          end
        end
      end
    end

    redirect_to :back
  end
end
