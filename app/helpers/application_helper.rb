module ApplicationHelper

  ##
  # Gets a collection of posts, and a specific post kind (eg. photo)
  # Returns the proper class for a kind of post (eg. status update)
  # based on the devision of the posts count for a specific kind and the max count
  # The result is a value between 0 and 1
  # ====Returns
  # * +String+ ->
  #               default, if the result is less than 0.05
  #               info, if the result is between 0.05 and 0.20
  #               primary, if the result is between 0.21 and less than 0.8
  #               success, if the result is between 0.8 and 1
  def posts_count_class(posts, kind)
    # Average posts per kind
    kinds_count = posts.group(:kind).count

    # Get ranges of values around average
    max_value = kinds_count.values.max.to_f
    ranges = []

    result = case (kinds_count[kind] || 0) / max_value
             when 0.8..1
               'success'
             when 0.21...0.8
               'primary'
             when 0.05..0.20
               'info'
             else
               'default'
             end
    return result
  end

  def graph_color_set(values_count)
    # If values are more than 7, choose another color scheme
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

  ##
  # Reactions distribution based on group_parameter
  # Counts the reactions, eg. per hour
  def reactions_groupped(page, reaction_kind: nil, group_parameter: 'day', group_format: nil, count: 'count')
    reactions = page.reactions
    # if groupping by date, do it by hand and do not show dates without data (ie w/ 0 count)
    result = { }
    reaction_objects = if reaction_kind
                         reactions.send(reaction_kind)
                       else
                         reactions.all
                       end
    other_reaction_objects = []
    other_reaction_objects = reactions.all - reactions.send(reaction_kind) if reaction_kind

    result[:multiple] = []

    if count == 'count'
      result[:simple] = reaction_objects.send("group_by_#{group_parameter}",
                                              :posted_at,
                                              format: group_format).count

      Reaction::KINDS.each do |reaction_kind|
        result[:multiple] << { name: reaction_kind,
                               data: reaction_objects.where(name: reaction_kind)
                                             .send("group_by_#{group_parameter}",
                                                   :posted_at,
                                                   format: group_format).send(count) }
      end

    elsif count == 'average'
      result[:simple] = reaction_objects
                        .group_by{|r| r.posted_at.strftime(group_parameter_options[group_parameter.to_sym][:format])}
                        .map { |k, v| [k, (v.size.to_f / v.pluck(:reactionable_type,
                                                                 :reactionable_id)
                                                                 .uniq.count).round(2) ] }.to_h


      result[:multiple] << { name: reaction_kind || 'all', data: result[:simple] }
      Reaction::KINDS.each do |reaction_kind|
        result[:multiple] << { name: reaction_kind,
                               data: reaction_objects.where(name: reaction_kind)
                                                     .group_by{ |reaction|
                                                                reaction
                                                                .posted_at
                                                                .strftime(group_parameter_options[group_parameter.to_sym][:format])
                                                              }
                                                     .map { |k, v| [k, (v.size.to_f / v.pluck(:reactionable_type,
                                                             :reactionable_id)
                                                      .uniq.count).round(2) ] }.to_h }
      end
    end

    return result
  end

  ##
  # Group options for reactions
  def group_parameter_options
    {  date: { group: 'day of month (1/2/etc)', format: '%b. %d, %Y', symbol: '%d' },
       day: { group: 'day of the week (Mon/Tue/etc)', format: '%A', symbol: '%A' },
       week: { group: 'week', format: '%Y-%m-%d', symbol: '%W' },
       month: { group: 'month', format: '%B', symbol: '%m' },
       year: { group: 'year', format: '%Y', symbol: '%Y' },
       hour: { group: 'hour_of_day', format: '%k:00', symbol: '%H'}
    }
  end

  ##
  # Reactions count for posts
  # Counts the reactions (per reaction kind) for all posts, and per post kind
  # ==== Returns
  # * +Hash+ --> { simple: { name: 'all', data: { like: 0, love: 0} },
  #                multiple: [ { name: 'all', data: { like: 0, love: 0 } },
  #                            { name: 'link', data: {} } ] }
  def posts_reactions_graph_data(page, kind=nil, count='count')
    result = { }
    result[:simple] = {}
    result[:simple][:data] = []
    result[:multiple] = {}
    return result unless page
    @page = page
    post_objects = page.posts.all

    if kind && kind != 'all'
      post_objects = page.posts.send(kind)
      # other_post_objects = Post.kinds.keys.
                                # map{ |post_kind| @page.posts.send(post_kind) unless post_kind == kind }.flatten.compact
      other_post_objects = page.posts.all - page.posts.send(kind)
    end
    result[:simple] = page.reactions.where(reactionable_type: 'Post', reactionable_id: post_objects.pluck(:id)).group(:name).send(count)

    reactions = Reaction::KINDS
    reactions.each do |reaction|
      unless result[:simple][reaction].present?
        result[:simple][reaction] = 0
      end
    end

    result[:multiple] = []
    result[:multiple] << { name: kind || 'all', data: result[:simple] }

    if kind && kind != 'all'
      result[:multiple] << { name: 'other posts',
                             data: page.reactions.where.not(reactionable: nil).
                                   where(reactionable_type: 'Post').
                                   where(reactionable_id: other_post_objects.pluck(:id)).
                                   group(:name).send(count) }
    else
      Post.kinds.keys.each do |post_kind|
        result[:multiple] << { name: post_kind,
                               data: @page.reactions.where(reactionable_type: 'Post',
                                                           reactionable_id: @page.posts.send(post_kind).pluck(:id)).
                                              group(:name).send(count)}
      end
    end

    result
  end

  ##
  # Find the top 3 posts, with the most total reactions
  # Gets the kind of the post (status, like, photo, link)
  # if there is no kind, it is applied for all posts
  def posts_max_reactions(kind=nil)
    post_objects = @page.posts.all
    post_objects = @page.posts.send(kind) if kind

    reactions_count = Reaction.where(reactionable: post_objects).group(:reactionable_id).count
    # Sort hashes by value (returns array). Keep the last 3 entries.
    reactions_max_count = reactions_count.sort_by{ |_k,v| v }.last(3).to_h

    posts = { }
    posts = reactions_max_count.map{ |k,_v| @page.posts.find(k) }

    posts
  end

  ##
  # Find the posts with the most reactions (per reaction)
  # ===Returns
  # * +Hash+ -> posts
  # posts = { 'like' => { count: 10, posts: PostsCollection } }
  def posts_per_max_reaction(kind=nil)
    reactions = ['like', 'love', 'haha', 'wow', 'sad', 'angry']
    posts = { }
    return posts unless @page

    post_objects = @page.posts.all
    post_objects = @page.posts.send(kind) if kind

    reactions_max = {}
    # Reaction.where(reactionable: post_objects).like.group(:reactionable_id).count
    # .select{ |k,v| k if v == t.values.max}.map{ |k,v| Post.find(k) }

    # reactions.each{ |r| reactions_max[r] = (Reaction.where(name: r, reactionable: post_objects).length || 0) }
    reactions.each{ |reaction|
      reaction_hash = Reaction.where(reactionable: post_objects).send(reaction).group(:reactionable_id).count
      max_reactions = reaction_hash.values.max
      reactionable_ids = reaction_hash.select{ |k,v| k if v == max_reactions }.keys
      posts[reaction] =  { count: max_reactions, posts: @page.posts.where(id: reactionable_ids) }
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
