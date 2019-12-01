FactoryBot.define do
  factory :person do
    sequence(:name) { |n| "My Name #{n}" }
    user
  end
end
