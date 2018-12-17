module Users
  class OmniauthCallbacksController < Devise::OmniauthCallbacksController
    skip_before_action :verify_authenticity_token
    skip_authorization_check

    User.omniauth_providers.each do |provider|
      define_method(provider) { handle(provider) }
    end

    private

    def handle(provider)
      auth_hash = request.env['omniauth.auth']
      user_access_token = auth_hash[:credentials][:token]
      uid = auth_hash[:uid]

      user = User.find_for_auth(auth_hash) # Get or create user

      begin
        user.access_token = user_access_token
        user.save!(validate: false)
        sign_in user

        # Create person
        person = Person.find_or_create_by(name: auth_hash[:info][:name],
                                          object_id: uid,
                                          user_id: user.id)

        # Create user pages
        user_access_token = current_user&.access_token
        @connection = Koala::Facebook::API.new(user_access_token)

        user_fb_pages = @connection.get_object("#{current_user.person.object_id}/accounts")
        user_fb_pages.each do |page|
          page_record = Page.find_or_create_by(name: page['name'],
                                               object_id: page['id'])
          page_record.pages_users.where(user: current_user).find_or_create_by(access_token: page['access_token'])
        end
      rescue => e
        flash[:error] = e.message
      end
      redirect_to root_path
    end
  end
end
