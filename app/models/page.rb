class Page < ApplicationRecord
  has_many :posts

  validates :object_id, uniqueness: true, presence: true
end
