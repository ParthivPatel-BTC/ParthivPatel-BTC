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

class Demographic < ApplicationRecord

  crypt_keeper :gender, :ethnicity, :total_household_income,
               :political_on_social, :political_on_economic, :english_as_primary,
               :language, :other_language, :birth_year, :highest_level_of_education,
               :postal_code_longest, :postal_code_current, :country,
               :number_of_people_in_household, :ethnicity_description,
               encryptor: :active_support,
               key: ENV['DEMOGRPAHIC_ENCRYPTION_KEY'], salt: ENV['DEMOGRPAHIC_ENCRYPTION_SALT']
  belongs_to :user, optional: true
  belongs_to :study_completion, optional: true
  belongs_to :feedback, optional: true
  validates_numericality_of :total_household_income, allow_nil: true
  validates :number_of_people_in_household, numericality: true, allow_blank: true
  validates_uniqueness_of :user_id, allow_nil: true
  GREATER_THAN_20 = -1.freeze

  # Note - From a Hash- We are storing values(of Hash) in the database and 
  # key(of Hash) for only countries
  ETHNICITY_HASH = {
    american_indian: 'American Indian or Alaska Native',
    asian: 'Asian',
    black_or_african: 'Black or African American',
    hispanic_or_latino: 'Hispanic or Latino',
    native_hawaiian: 'Native Hawaiian or Pacific Islander',
    white: 'White',
    other: 'Other'
  }.freeze

  EDUCATION_HASH = {
    blank: '',
    none: 'none',
    elementary: 'elementary',
    high_school_or_no_degree: 'high school no degree',
    high_school: 'high school graduate',
    some_college: 'some college',
    associates_degree: 'associates degree',
    bachelors_degree: 'bachelors degree',
    masters_degree: 'masters degree',
    professional_school_degree: 'professional school degree',
    doctorate_degree: 'doctorate degree'
  }.freeze

  GENDER_HASH = {
    blank: '',
    male: 'male',
    female: 'female',
    other: 'other'
  }.freeze

  POLITICAL_ON_SOCIAL_HASH = {
    none: '',
    extremely_liberal: 'extremely liberal',
    liberal: 'liberal',
    moderate: 'moderate',
    conservative: 'conservative',
    extremely_conservative: 'extremely conservative'
  }.freeze

  POLITICAL_ON_ECONOMIC_HASH = {
    none: '',
    extremely_liberal: 'extremely liberal',
    liberal: 'liberal',
    moderate: 'moderate',
    conservative: 'conservative',
    extremely_conservative: 'extremely conservative'
  }.freeze


  def total_household_income=(num)
    num.gsub!(',', '') if num.is_a?(String)
    self[:total_household_income] = num.to_i
  end

  def birth_year
    read_attribute(:birth_year).try(:to_i)
  end

  def total_household_income
    read_attribute(:total_household_income).try(:to_i)
  end

  def downloadable_attributes_values
    Download::DEMOGRAPHIC_HEADERS.inject([]) do |val_array, attr|
      attr_value = if attr == 'number_of_people_in_household' && self.number_of_people_in_household.to_i == GREATER_THAN_20
                     21
                   else
                     self.send("#{attr}".to_sym)
                   end
      val_array.push(attr_value)
    end
  end

  class << self
    def average_household_income
      total_inc = self.select(:total_household_income).map(&:total_household_income).compact
      (total_inc.sum / total_inc.count).floor rescue 0
    end

    def percent_male
      ((self.search_by_plaintext(:gender, GENDER_HASH[:male]).count / self.count.to_f) * 100).round(2)
    end

    def percent_female
      ((self.search_by_plaintext(:gender, GENDER_HASH[:female]).count / self.count.to_f) * 100).round(2)
    end

    def percent_other
      ((self.search_by_plaintext(:gender, GENDER_HASH[:other]).count / self.count.to_f) * 100).round(2)
    end

    def percent_english
      ((self.search_by_plaintext(:language, GlobalConstants::DEMOGRAPHICS[:language][:english]).count / self.count.to_f) * 100).round(2)
    end

    def political_on_social_hash
      total_entries = self.count.to_f
      political_hash = {}
      POLITICAL_ON_SOCIAL_HASH.values.each do |political_view|
        political_hash[political_view] = ((self.search_by_plaintext(:political_on_social, political_view).count / total_entries) * 100).round(2)
      end

      political_hash
    end

    def political_on_economic_hash
      total_entries = self.count.to_f
      political_hash = {}
      POLITICAL_ON_ECONOMIC_HASH.values.each do |political_view|
        political_hash[political_view] = ((self.search_by_plaintext(:political_on_economic, political_view).count / total_entries) * 100).round(2)
      end

      political_hash
    end

    def education_hash
      total_entries = self.count.to_f
      edu_hash = {}
      EDUCATION_HASH.values.each do |education|
        edu_hash[education] = ((self.search_like_plaintext(:highest_level_of_education, education).count / total_entries) * 100).round(2)
      end

      edu_hash
    end

    def ethnicity_hash
      total_entries = self.count.to_f
      eth_hash = {}
      ETHNICITY_HASH.values.each do |ethnicity|
        eth_hash[ethnicity] = ((self.search_like_plaintext(:ethnicity, ethnicity).count / total_entries) * 100).round(2)
      end
      eth_hash
    end
  end
end
