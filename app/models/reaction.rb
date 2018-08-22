class Reaction < ApplicationRecord
  belongs_to :reactionable, polymorphic: true

  validates :object_id, uniqueness: true
end
