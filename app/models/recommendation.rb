class Recommendation
  include ActiveModel::Model
  extend ActiveModel::Translation
  attr_accessor :to, :referral

  validates :to, :referral, presence: true
  validates :to, :referral, email_format: { message: 'e-mail not valid' }, allow_blank: false
end
