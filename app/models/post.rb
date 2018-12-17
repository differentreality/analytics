class Post < ApplicationRecord
  belongs_to :page
  has_many :reactions, as: :reactionable, dependent: :destroy

  enum kind: [:link, :status, :photo, :video, :offer, :event]

  validates :object_id, uniqueness: true, presence: true
  validates :page_id, presence: true
end
