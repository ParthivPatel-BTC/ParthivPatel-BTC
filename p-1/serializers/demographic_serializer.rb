# frozen_string_literal: true

# == Schema Information
#
# Table name: demographics
#
#  id                            :bigint           not null, primary key
#  user_id                       :integer
#  gender                        :text
#  ethnicity                     :text
#  total_household_income        :text
#  political_on_social           :text
#  political_on_economic         :text
#  english_as_primary            :text
#  birth_year                    :text
#  highest_level_of_education    :text
#  created_at                    :datetime         not null
#  updated_at                    :datetime         not null
#  study_completion_id           :integer
#  postal_code_longest           :text
#  postal_code_current           :text
#  number_of_people_in_household :text
#  integer                       :string
#  user_session_id               :string
#  ethnicity_description         :text
#  feedback_id                   :integer
#  country                       :text
#  language                      :text
#  other_language                :text
#


class DemographicSerializer < BaseSerializer
  attributes :id,
             :gender,
             :birth_year,
             :ethnicity,
             :ethnicity_description,
             :highest_level_of_education,
             :total_household_income,
             :political_on_social,
             :political_on_economic,
             :number_of_people_in_household,
             :language,
             :other_language,
             :country,
             :postal_code_longest,
             :postal_code_current
end
