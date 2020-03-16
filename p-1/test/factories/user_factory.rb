# FactoryBot.define do
#   factory :user do
#     email
#     password "12345678"
#     password_confirmation "12345678"

#     trait :with_study_completions do
#       after(:create) do |user|
#         user.study_completions = [create(:study_completion)]#.each do |study_completion|
#           #study_completion.save!
#         #end
#       end
#     end

#     factory :user_with_study_completions, traits: [:with_study_completions]
#   end
# end