FactoryBot.define do
  factory :user_device_sync do
    user { nil }
    device_id { "MyString" }
    last_sync_at { "MyString" }
  end
end
