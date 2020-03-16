# frozen_string_literal: true

# == Schema Information
#
# Table name: study_completions
#
#  id                            :bigint           not null, primary key
#  user_id                       :integer
#  study_id                      :integer
#  completed_on                  :text
#  score                         :text
#  created_at                    :datetime         not null
#  updated_at                    :datetime         not null
#  custom_study_results          :text
#  similar_experiment            :text
#  technical_problems            :text
#  did_you_cheat                 :text
#  people_in_room                :text
#  comments                      :text
#  taken_survey_before           :text
#  cheating_description          :text
#  started_at                    :text
#  start_count                   :text
#  technical_problem_description :text
#  user_session_id               :string
#  feedback_id                   :integer
#  mobile_completion_id          :string
#  notification                  :integer          default(1)
#

class StudyCompletion < ApplicationRecord
  include StudyCompletions::GradientScoreComputation

  before_create :modify_mobile_completion_id
  validates :completed_on, presence: true

  paginates_per GlobalConstants::RESULTS_PER_PAGE
  belongs_to :user, optional: true
  belongs_to :study
  belongs_to :feedback, optional: true
  has_one :demographic, autosave: true
  before_create :set_study_start_data
  after_create :delete_study_start_entry
  GREATER_THAN_50 = -1.freeze

  crypt_keeper :completed_on, :score, :custom_study_results,
               :similar_experiment, :technical_problems, :did_you_cheat,
               :people_in_room, :comments, :taken_survey_before,
               :cheating_description, :started_at, :start_count,
               :technical_problem_description,
               encryptor: :active_support,
               key: ENV['STUDY_COMPLETION_ENCRYPTION_KEY'], salt: ENV['STUDY_COMPLETION_ENCRYPTION_SALT']

  def completed_on
    read_attribute(:completed_on).try(:in_time_zone)
  end

  def score
    read_attribute(:score).try(:to_f)
  end

  def people_in_room
    read_attribute(:people_in_room).try(:to_i)
  end

  def taken_survey_before?
    read_attribute(:taken_survey_before) == 'true'
  end

  def taken_survey_before
    read_attribute(:taken_survey_before) == 'true'
  end

  def started_at
    read_attribute(:started_at).try(:in_time_zone)
  end

  def start_count
    read_attribute(:start_count).try(:to_i)
  end

  def average_score_as_percent_of_max
    if study.average_score && study.max_score
      ((study.average_score / study.max_score) * 100)
    else
      0
    end
  end

  def rounded_average_score
    if study.average_score
      study.average_score.round(2)
    else
      0
    end
  end

  def score_as_percent_of_max
    if score && study.max_score
      ((score / study.max_score) * 100)
    else
      0
    end
  end

  def custom_results_parsed
    if study.json_results_schema.file && custom_study_results
      JSON.parse(custom_study_results)
    else
      []
    end
  end

  def self.EMA_custom_results(study_id:, user_id:)
    records = []
    custom_study_results = StudyCompletion.where(user_id: user_id, study_id: study_id).pluck(:notification, :custom_study_results)
    custom_study_results.each do |i|
      if i[1].present?
        record = {}
        record["#{i[0]}"] = JSON.parse(i[1]) 
        records << record
      end
    end
    records
  end

  def self.to_csv
    # we gotta build it into two giant arrays

    attributes = %w[id name]
    CSV.generate(headers: true) do |csv|
      csv << attributes

      Study.all.each do |ue|
        csv << ue.attributes.values_at(*attributes)
      end
    end
  end

  def downloadable_attributes_values
    Download::STUDY_COMPLETION_HEADERS.inject([]) do |val_array, attr|
      attr_value = if attr == 'people_in_room' && people_in_room.to_i == GREATER_THAN_50
                     51
                   else
                     send(attr.to_s.to_sym)
                   end
      val_array.push(attr_value)
    end
  end

  def set_study_start_data
    if user_id
      user_study = UserStudy.where(user_id: user_id, study_id: study_id).first
      return if user_study.blank? # should never happen

      self.started_at = user_study.started_at
      self.start_count = user_study.start_count
    end
  end

  def delete_study_start_entry
    UserStudy.find_by(user_id: user_id, study_id: study_id)&.destroy if user_id
  end

  def self.get_scores_array(study_id)
    where(study_id: study_id).pluck(:score).map(&:to_f)
  end

  def study_data
    @study_data ||= study
  end

  def self.create_study_completion(studies, params)
    result = OpenStruct.new(
      error_studies_ids: [],
      created_studies_ids: [],
      studies_completion: [],
      single_study: false
    )
    studies.each_with_index do |study, index|
      result.studies_completion << StudyCompletion.create!(study[:study])
      result.single_study = true if study.dig(:study, :mobile_completion_id).blank?
      result.created_studies_ids << mobile_id(index, params)
    rescue Exception => e
      result.error_studies_ids << mobile_id(index, params)
      Rollbar.error('error in create',
                    class_name: study.class.name,
                    object_info: study,
                    errors: e.class.name,
                    backtrace: e.backtrace
                  )
    end
    result
  end

  def self.mobile_id(index, params)
    params[:studies][:studies][index][:study][:mobile_completion_id]
  end

  def modify_mobile_completion_id
    self.mobile_completion_id = "#{mobile_completion_id}:#{user_id}:#{completed_on.to_i}"
  end
end
