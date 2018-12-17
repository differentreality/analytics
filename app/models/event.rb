class Event < ApplicationRecord
  belongs_to :page
  has_many :reactions, as: :reactionable, dependent: :destroy

  validates :object_id, uniqueness: true, presence: true
end
