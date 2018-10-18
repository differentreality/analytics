class WebhooksController < ApplicationController
  # Receives
  # GET https://www.your-clever-domain-name.com/webhooks?
  # hub.mode=subscribe&
  # hub.challenge=1158201444&
  # hub.verify_token=meatyhamhock

  # Must return the hub.challenge value
  def confirm_webhook
    if params['hub.verify_token'] == ENV['webhook_verify_token']
      render plain: params['hub.challenge']
    else
      render plain: 'Error!'
    end
  end

  # {"entry"=> [{"changes"=>
               # [{"field"=>"feed", "value"=> {"reaction_type"=>"like", "from"=>{"id"=>"2037320319611866",
                                                                    # "name"=>"Stella   Rouzi Differentreality"},
                                      # "parent_id"=>"295754757450351_637257263300097", "post_id"=>"295754757450351_637257263300097", "verb"=>"remove", "item"=>"reaction", "created_time"=>1534875091}}],
    # "id"=>"295754757450351", "time"=>1534875092}],

    # "object"=>"page", "home"=>{"entry"=>[{"changes"=>[{"field"=>"feed", "value"=>{"reaction_type"=>"like", "from"=>{"id"=>"2037320319611866", "name"=>"Stella Rouzi Differentreality"}, "parent_id"=>"295754757450351_637257263300097", "post_id"=>"295754757450351_637257263300097", "verb"=>"remove", "item"=>"reaction", "created_time"
    # =>1534875091}}], "id"=>"295754757450351", "time"=>1534875092}], "object"=>"page"}}

  def webhook_notification
    verb = params['entry'].first['changes'].first['value']['verb']
    posted_at = Time.at(params['entry'].first['changes'].first['value']['created_time'])
    post_id = params['entry'].first['changes'].first['value']['post_id']
    post = Post.where(object_id: post_id).first_or_create

    if verb == 'add'
      reaction_type = params['entry'].first['changes'].first['value']['reaction_type']
      reaction = Reaction.create!(reactionable: post, name: reaction_type, posted_at: posted_at)
    elsif verb == 'remove'
      reaction_type = params['entry'].first['changes'].first['value']['item']
    end

    head :ok
  end
end
