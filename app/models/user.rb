class User < ApplicationRecord
  has_one :person
  has_many :pages_users, dependent: :destroy
  has_many :pages, through: :pages_users
  devise :omniauthable, omniauth_providers: [:facebook]

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
