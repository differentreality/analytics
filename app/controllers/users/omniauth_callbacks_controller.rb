module Users
  class OmniauthCallbacksController < Devise::OmniauthCallbacksController
    skip_before_action :verify_authenticity_token
    skip_authorization_check

    User.omniauth_providers.each do |provider|
      define_method(provider) { handle(provider) }
    end

    def failure
      Rails.logger.debug "Omniauth authentication failed with error #{params[:error_code]}, #{params[:error_message]}"
      flash[:error] = 'Unfortunately we could not authenticate you. Please try again or contact us.'
      redirect_to root_path
    end

    private

    def handle(provider)
      auth_hash = request.env['omniauth.auth']
      user_access_token = auth_hash[:credentials][:token]
      uid = auth_hash[:uid]

      begin
        user = User.find_for_auth(auth_hash) # Get or create user
        user.access_token = user_access_token
        user.save!(validate: false)
        sign_in user

        # Create person
        person = Person.find_or_create_by(name: auth_hash[:info][:name],
                                          object_id: uid,
                                          user_id: user.id)

        current_user.get_pages
      rescue => e
        flash[:error] = e.message
      end
      redirect_to root_path
    end
  end
end
