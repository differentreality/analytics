class Page < ApplicationRecord
  has_many :posts
  has_many :events
  has_many :reactions

  has_many :pages_users, dependent: :destroy
  has_many :users, through: :pages_users

  validates :object_id, uniqueness: true, presence: true
end
