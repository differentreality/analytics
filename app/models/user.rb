class User < ApplicationRecord
  has_one :person
  has_many :pages_users, dependent: :destroy
  has_many :pages, through: :pages_users
  devise :omniauthable, omniauth_providers: [:facebook]

  def get_pages
    begin
      connection = Koala::Facebook::API.new(access_token)

      user_fb_pages = connection.get_object('me/accounts')
      user_fb_pages.each do |page|
        page_record = Page.find_or_create_by(name: page['name'],
                                             object_id: page['id'])
        pages_users_record = page_record.pages_users.find_by(user: self)

        if pages_users_record
          pages_users_record.update(access_token: page['access_token'])
        else
          page_record.pages_users.create!(user: self, access_token: page['access_token'])
        end
      end
    rescue => e
      Rails.logger.info "Could not get user pages: #{e.message}"
    end
  end

  # Searches for user based on email. Returns found user or new user.
  # ====Returns
  # * +User::ActiveRecord_Relation+ -> user
  def self.find_for_auth(auth)
    user = User.where(email: auth.info.email).first_or_initialize

    if user.new_record?
      user.email = auth.info.email
    end
    user
  end
end
