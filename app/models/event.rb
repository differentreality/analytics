class Event < ApplicationRecord
  has_many :reactions, as: :reactionable, dependent: :destroy

  validates :object_id, uniqueness: true, presence: true
end
