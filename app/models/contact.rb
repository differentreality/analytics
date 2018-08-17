class Contact
  include ActiveModel::Model

  attr_accessor :email, :body, :subject

  validates :body, :subject, presence: true
end
