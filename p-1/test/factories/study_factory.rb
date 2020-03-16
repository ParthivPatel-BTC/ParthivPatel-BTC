# FactoryBot.define do
#   sequence :email do |n|
#     "person#{n}@example.com"
#   end


#   factory :study do
#     name Faker::Lorem.sentence
#     description "a description!"
#   end

#   factory :study_completion do
#     study

#     trait :logged_out do
#       user_id nil
#     end

#     factory :logged_out_study_completion, traits: [:logged_out]
#   end


#   factory :end_of_study do
#     trait :first_time_taking_study do
#       taken_survey_before false
#     end

#     trait :has_taken_study_before do
#       taken_survey_before true
#     end

#     factory :first_time_study_taker, traits: [:first_time_taking_study]
#     factory :repeat_study_taker, traits: [:has_taken_study_before]
#   end

# end

# we need a study with a completion that has a 