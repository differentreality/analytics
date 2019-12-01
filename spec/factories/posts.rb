FactoryBot.define do
  factory :post do
    sequence(:page_id) { |n| n }
    message { 'Post content text!' }
    sequence(:object_id) { |n| "#{n}#{n}"}
    kind { 'status' }
    posted_at { Time.current }

    factory :post_status do
      kind { 'status' }
    end

    factory :post_link do
      kind { 'link' }
    end

    factory :post_photo do
      kind { 'photo' }
    end

    factory :post_video do
      kind { 'video' }
    end

    factory :post_offer do
      kind { 'offer' }
    end

    factory :post_event do
      kind { 'event' }
    end

    factory :post_note do
      kind { 'note' }
    end
  end
end
