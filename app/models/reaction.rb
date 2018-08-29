class Reaction < ApplicationRecord
  belongs_to :reactionable, polymorphic: true

  validates :name, uniqueness: { scope: [:reactionable_type, :reactionable_id] }
end
