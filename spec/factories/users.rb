FactoryBot.define do
  factory :user do
    sequence(:email) { |n| "example#{n}@example.com" }
    created_at { Date.today }
  end
end
