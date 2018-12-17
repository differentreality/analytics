class Fan < ApplicationRecord
  belongs_to :page

  serialize :city, Hash
  serialize :country, Hash
  serialize :gender, Hash
  serialize :age_range, Hash
end
