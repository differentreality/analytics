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
      puts "auth_hash: #{auth_hash}"
      uid = auth_hash[:uid]

      # user_accounts = @connection.get_object("#{uid}/accounts")
      # puts "user accounts: #{user_accounts}"

      user = User.find_for_auth(auth_hash) # Get or create users
      puts "user: #{user.inspect}"
      begin
        # user.skip_confirmation!
        user.save!(validate: false)
        person = Person.new(name: auth_hash[:info][:name],
                            object_id: uid,
                            user_id: user.id)
        puts "person: #{person.inspect}"
        person.save!
        # current_user = user
        sign_in user
      rescue => e
        puts "ERROR: #{e.message}"
        flash[:error] = e.message
      end
      redirect_to root_path
    end
  end
end
