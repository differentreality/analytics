class CityFan < ApplicationRecord
  belongs_to :page

  validates :municipality, uniqueness: { scope: [:date, :page_id] }
  validates :page_id, presence: true
end
