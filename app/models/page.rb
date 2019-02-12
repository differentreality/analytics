class Page < ApplicationRecord
  has_many :posts, dependent: :destroy
  has_many :events, dependent: :destroy
  has_many :reactions, dependent: :destroy
  has_many :city_fans, dependent: :destroy
  has_many :age_fans, dependent: :destroy

  has_many :pages_users, dependent: :destroy
  has_many :users, through: :pages_users

  validates :object_id, uniqueness: true, presence: true

  def self.default
    find_by(default: true)
  end

  def to_param
    object_id
  end
end
