FactoryBot.define do
  factory :page do
    sequence(:name) { |n| "My FacebooK Page #{n}" }
    sequence(:object_id) { |n| "#{n}#{n}"}
  end

  factory :page_default do
    default { true }
  end
end
