class PagesUser < ApplicationRecord
  belongs_to :page
  belongs_to :user

  validates :user_id, :page_id, presence: true
  validates :user_id, uniqueness: { scope: :page_id }
end
