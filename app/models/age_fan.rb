class AgeFan < ApplicationRecord
  belongs_to :page

  enum gender: [:female, :male, :undefined]
  enum age_range: ['13-17', '18-24', '25-34', '35-44', '45-54', '55-64', '65+']

  validates :age_range, uniqueness: { scope: [:gender, :date, :page_id] }
  validates :page_id, presence: true
end
