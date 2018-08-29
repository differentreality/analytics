module ApplicationHelper
  # Gets hash of overall stats result and returns it in text
  # ==== Gets
	# * +Hash+ -> {"02"=>1, "04"=>1, "14"=>1}
  # ==== Returns
  # * +String+ -> "02, 04, 14 -> 1"
  def overall_stats_text(object)
    return "#{object.keys.join(', ')} -> #{object.values.first}"
  end

  def reactions_total_count(reactioanble)
    Reaction.where(reactioanble: reactioanble).sum(:count)
  end

  def posts_max_reactions(kind=nil)
    post_objects = Post.all
    post_objects = Post.send(kind) if kind

    max_reactions_count = post_objects.map{ |p| p.reactions.sum(:count) }.max

    posts = { }
    posts = post_objects.select{ |p| p.reactions.sum(:count) == max_reactions_count }
    posts
  end

  def posts_per_max_reaction(kind=nil)
    reactions = ['like', 'love', 'haha', 'wow', 'sad', 'angry']

    post_objects = Post.all
    post_objects = Post.send(kind) if kind

    reactions_max = {}
    reactions.each{ |r| reactions_max[r] = (Reaction.where(name: r, reactionable: post_objects).maximum(:count) || 0) }

    posts = { }
    reactions.each{ |r| if reactions_max[r] > 0 then
                          posts[r] = {};
                          posts[r][:count] = reactions_max[r];
                          posts[r][:posts] = Reaction.where(name: r, count: reactions_max[r], reactionable: post_objects).map(&:reactionable)
                        end }
    posts
  end

  def icon_for(reaction)
    case reaction
    when 'like'
      'fa-thumbs-up'
    when 'love'
      'fa-heart'
    when 'wow'
      'fa-surprise'
    when 'haha'
      'fa-laugh'
    when 'sad'
      'fa-sad-tear'
    when 'angry'
      'fa-angry'
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
