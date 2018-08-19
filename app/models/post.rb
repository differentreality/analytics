class Post < ApplicationRecord
  enum kind: [:link, :status, :photo, :video, :offer, :event]

  validates :object_id, uniqueness: true
end
