module ApplicationHelper
  # Gets hash of overall stats result and returns it in text
  # ==== Gets
	# * +Hash+ -> {"02"=>1, "04"=>1, "14"=>1}
  # ==== Returns
  # * +String+ -> "02, 04, 14 -> 1"
  def overall_stats_text(object)
    return "#{object.keys.join(', ')} -> #{object.values.first}"
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
