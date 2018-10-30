module ApplicationHelper

  def graph_color_set
    return ['#5b90bf', '#96b5b4', '#adc896', '#ab7967', '#d08770', '#b48ead']
  end

  def hour_range_text(hours_array)
    # result.second[:hour][:max].keys   .join(', ')
    result = hours_array.map{ |hour| "#{hour}:00 - #{hour.to_i + 1}:00" }.join(', ')
    return result
  end

  def find_date(period)
    period = period.parameterize.underscore

    result = case period
             when 'all'
               { from: '', to: '' }
             when 'current_year'
               { from: Date.new(Date.current.year).to_s, to: Date.new(Date.current.year).end_of_year.to_s }
             when 'last_3_months'
               { from: (Date.current - 3.months).to_s, to: Date.current.to_s }
             when 'last_6_months'
               { from: (Date.current - 6.months).to_s, to: Date.current.to_s }
             when 'last_year'
               { from: Date.new(Date.current.year - 1).to_s, to: Date.new(Date.current.year - 1).end_of_year.to_s }
             end

    return result
  end

  # Gets hash of overall stats result and returns it in text
  # ==== Gets
	# * +Hash+ -> {"02"=>1, "04"=>1, "14"=>1}
  # ==== Returns
  # * +String+ -> "02, 04, 14 -> 1"
  def overall_stats_text(object)
    return "#{object.keys.join(', ')} -> #{object.values.first}"
  end

  def posts_reactions_graph_data(kind=nil)
    result = { }
    post_objects = Post.all
    if kind && kind != 'all'
      post_objects = Post.send(kind)
      # other_post_objects = Post.kinds.keys.
                                # map{ |post_kind| Post.send(post_kind) unless post_kind == kind }.flatten.compact
      other_post_objects = Post.all - Post.send(kind)
    end
    result[:simple] = { name: kind || 'all', data: Reaction.where(reactionable: post_objects).group(:name).count }

    # reactions = ['like', 'love', 'haha', 'wow', 'sad', 'angry']

    result[:multiple] = []
    if kind && kind != 'all'
      result[:multiple] << result[:simple]
      result[:multiple] << { name: 'other posts',
                             data: Reaction.where.not(reactionable: nil).
                                   where(reactionable_type: 'Post').
                                   where(reactionable_id: other_post_objects.pluck(:id)).
                                   group(:name).count }
    else
      Post.kinds.keys.each do |post_kind|
        result[:multiple] << { name: post_kind,
                               data: Reaction.where(reactionable_type: 'Post',
                                                    reactionable_id: Post.send(post_kind)).
                                              group(:name).count}
      end
    end

    result
  end

  ##
  # Find the top 3 posts, with the most total reactions
  # Gets the kind of the post (status, like, photo, link)
  # if there is no kind, it is applied for all posts
  def posts_max_reactions(kind=nil)
    post_objects = Post.all
    post_objects = Post.send(kind) if kind

    reactions_count = Reaction.where(reactionable: post_objects).group(:reactionable_id).count
    # Sort hashes by value (returns array). Keep the last 3 entries.
    reactions_max_count = reactions_count.sort_by{ |_k,v| v }.last(3).to_h

    posts = { }
    posts = reactions_max_count.map{ |k,_v| Post.find(k) }

    posts
  end

  ##
  # Find the posts with the most reactions (per reaction)
  # ===Returns
  # * +Hash+ -> posts
  # posts = { 'like' => { count: 10, posts: PostsCollection } }
  def posts_per_max_reaction(kind=nil)
    reactions = ['like', 'love', 'haha', 'wow', 'sad', 'angry']

    post_objects = Post.all
    post_objects = Post.send(kind) if kind
    puts "kind: #{kind} and post_objects: #{post_objects.count}"

    reactions_max = {}
    # Reaction.where(reactionable: post_objects).like.group(:reactionable_id).count
    # .select{ |k,v| k if v == t.values.max}.map{ |k,v| Post.find(k) }

    # reactions.each{ |r| reactions_max[r] = (Reaction.where(name: r, reactionable: post_objects).length || 0) }
    posts = { }
    reactions.each{ |reaction|
      reaction_hash = Reaction.where(reactionable: post_objects).send(reaction).group(:reactionable_id).count
      max_reactions = reaction_hash.values.max
      reactionable_ids = reaction_hash.select{ |k,v| k if v == max_reactions }.keys
      posts[reaction] =  { count: max_reactions, posts: Post.where(id: reactionable_ids) }
    }

    # Reaction.where(name: r, reactionable: post_objects)
    # reactions.each{ |r| if reactions_max[r] > 0 then
    #                       posts[r] = {};
    #                       posts[r][:count] = reactions_max[r];
    #                       posts[r][:posts] = post_objects.select{ |post| post.reactions.count == reactions_max[r] }
    #                     end }
    posts
  end

  def icon_for(reaction)
    case reaction
    when 'like'
      'fa-thumbs-up text-primary'
    when 'love'
      'fa-heart text-danger'
    when 'wow'
      'fa-surprise text-success'
    when 'haha'
      'fa-laugh text-warning'
    when 'sad'
      'fa-sad-tear text-info'
    when 'angry'
      'fa-angry text-danger'
    end
  end

  def resource_name
    :user
  end

  def resource
    @resource ||= User.new
  end

  def devise_mapping
    @devise_mapping ||= Devise.mappings[:user]
  end

  def omniauth_configured
    providers = []
    Devise.omniauth_providers.each do |provider|
      provider_key = "#{provider}_key"
      provider_secret = "#{provider}_secret"
      key = Rails.application.secrets.send(provider_key) || ENV["#{provider.upcase}_KEY"]
      secret = Rails.application.secrets.send(provider_secret) || ENV["#{provider.upcase}_SECRET"]
      unless key.blank? || secret.blank?
        providers << provider
      end
    end
    providers
  end

  def bootstrap_class_for(flash_type)
    logger.debug "flash_type is #{flash_type}"
    case flash_type
    when 'success'
      'alert-success'
    when 'error'
      'alert-danger'
    when 'alert'
      'alert-warning'
    when 'notice'
      'alert-info'
    else
      flash_type.to_s
    end
  end
end
