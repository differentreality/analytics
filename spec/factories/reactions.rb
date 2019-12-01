FactoryBot.define do
  factory :reaction do
    page
    person
    name { 'like' }
    association :reactionable, factory: :post

    factory :reaction_like do
      name { 'like' }
    end

    factory :reaction_love do
      name { 'love' }
    end

    factory :reaction_wow do
      name { 'wow' }
    end

    factory :reaction_haha do
      name { 'haha' }
    end

    factory :reaction_sad do
      name { 'sad' }
    end

    factory :reaction_angry do
      name { 'angry' }
    end
  end
end
