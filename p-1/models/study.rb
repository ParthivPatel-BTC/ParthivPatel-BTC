# frozen_string_literal: true

# == Schema Information
#
# Table name: studies
#
#  id                            :bigint           not null, primary key
#  name                          :string
#  description                   :string
#  embed_code                    :string
#  preview_image                 :string
#  estimated_completion_time     :string
#  created_at                    :datetime         not null
#  updated_at                    :datetime         not null
#  max_score                     :decimal(10, 1)
#  css_url                       :string
#  study_order                   :integer
#  js_presentation_url           :string
#  purpose_of_study              :text
#  understading_the_results      :text
#  related_research              :text
#  json_results_schema           :string
#  published                     :boolean          default(FALSE)
#  created_by                    :integer
#  mobile_embed_code             :string
#  mobile_js_presentation_url    :string
#  type                          :string
#  pre_registration_start_date   :datetime
#  mobile_preview_image          :string
#  frequency                     :integer
#  start_date                    :datetime
#  same_notification             :boolean
#  same_study_material           :boolean
#  number_of_notification        :integer
#  aasm_state                    :string           default("draft")
#  pre_registration_required     :boolean          default(FALSE)
#  registration_page_description :string
#  split_week                    :boolean          default(FALSE)
#

class Study < ApplicationRecord
  paginates_per GlobalConstants::STUDIES_PER_PAGE
  acts_as_ordered_taggable
  has_rich_text :purpose_of_study
  has_rich_text :understading_the_results
  has_rich_text :related_research

  before_create :set_study_order
  before_update :delete_pre_registration_details

  REMINDER_SPACING = [['15 min', 15], ['30 min', 30], ['45 min', 45], ['60 min', 60]].freeze
  ESTIMATED_COMPLETION_IN = { minutes: 'Mins', hours: 'Hrs' }.freeze
  STUDY_TYPE = { General: 'General', EmaDaily: 'EMA Daily', EmaWeekly: 'EMA Weekly' }.freeze
  NUMBER_OF_NOTIFICATION = [1, 2, 3]
  GENERAL_TYPE = 'General'
  EMA_DAILY_TYPE = 'EmaDaily'
  EMA_WEEKLY_TYPE = 'EmaWeekly'
  MINUTES = 'minutes'
  HOURS = 'hours'
  IST_MODEL_NAME = { 'General' => :general, 'EmaDaily' => :ema_daily, 'EmaWeekly' => :ema_weekly }.freeze

  include AASM

  aasm do
    state :draft, initial: true
    state :active, :inactive
    event :activated do
      transitions from: :draft, to: :active
    end
    event :deactivated do
      transitions from: :active, to: :draft
    end
  end

  has_many :study_completions, dependent: :destroy do
    def most_recent_study_completions
      ordered_combined_results('DESC')
    end

    def all_first_time_completions
      ordered_combined_results('ASC')
    end

    def logged_in_first_time_completions
      self.select('DISTINCT ON(user_id) *').order('user_id, study_completions.created_at ASC')
    end

    def ordered_combined_results(order)
      logged_out_completions = logged_out_first_time_and_most_recent_completions
      logged_in_completions = where.not(user_id: nil)
      combined_results = logged_out_completions.or(logged_in_completions)
      combined_results.select('DISTINCT ON(user_id) *').order("user_id, study_completions.created_at #{order}")
    end

    def logged_out_first_time_and_most_recent_completions
      ids = begin
              search_by_plaintext(:taken_survey_before, false).map(&:id)
            rescue StandardError
              []
            end
      where(user_id: nil, id: ids)
    end
  end
  has_many :user_studies, dependent: :destroy, foreign_key: :study_id
  has_many :users, through: :study_completions
  has_many :study_details, dependent: :destroy
  has_many :study_group_notifications, dependent: :destroy
  has_many :user_notifications, dependent: :destroy
  accepts_nested_attributes_for :study_details
  has_many :user_study_pre_registrations, dependent: :destroy
  belongs_to :creator, class_name: 'User', foreign_key: :created_by
  mount_uploader :preview_image, ImageUploader
  mount_uploader :mobile_preview_image, ImageUploader
  mount_uploader :embed_code, StudyJavascriptUploader
  mount_uploader :mobile_embed_code, StudyJavascriptUploader
  mount_uploader :css_url, StudyCssUploader
  mount_uploader :js_presentation_url, StudyJsPresentationUploader
  mount_uploader :mobile_js_presentation_url, StudyJsPresentationUploader
  mount_uploader :json_results_schema, JsonResultsSchemaUploader

  scope :is_published, -> { where(published: true) }

  validates :max_score, :estimated_completion_time, :type, :preview_image, :mobile_preview_image, presence: true, if: :active?
  validates_numericality_of :max_score, greater_than_or_equal_to: 1, less_than_or_equal_to: 100000, if: :active?
  validates_associated :study_details, message: proc { |_p, meta| study_details_message(meta) }
  validate :valid_start_date, if: :active?
  validates :description, :registration_page_description, length: { minimum: 0, maximum: 100 }, allow_blank: true, if: :active?
  validate :file_extension, if: :active?

  def file_extension
    validate_file('js_presentation_url', 'Presentation JS', 'js')
    validate_file('mobile_js_presentation_url', 'Presentation Mobile JS', 'js')
    validate_file('json_results_schema', 'Json Result Schema', 'json')
    validate_file('css_url', 'Stylesheet(.css file)', 'css')
  end

  def valid_start_date
    if pre_registration_required == true
      if pre_registration_start_date.blank?
        errors[:pre_registration_start_date] << 'is required'
      end
      if start_date.present?
        unless start_date.strftime(GlobalConstants::DATE_ONLY_YMD) >= DateTime.now.strftime(GlobalConstants::DATE_ONLY_YMD)
          errors[:start_date] << 'must be greater than or equal to current date' if aasm_state_was == 'draft'
        end
      else
        errors[:start_date] << '^study start date is required'
      end
      if start_date.present? && pre_registration_start_date.present?
        unless start_date.strftime(GlobalConstants::DATE_ONLY_YMD) >= pre_registration_start_date&.strftime(GlobalConstants::DATE_ONLY_YMD)
          errors[:start_date] << 'must be greater than registration date'
        end
      end
    end
  end

  def self.study_details_message(meta)
    e = []
    meta[:value].each do |study_detail|
      study_detail.errors.full_messages.each do |error|
        e << error
      end
    end
    e.uniq
  end

  validate :validate_image_size, if: :active?
  validate :validate_mobile_image_size, if: :active?
 
  validates :name, presence: true
  before_save :set_default_preview_image
  after_save :crop_image
  
  def validate_image_size
    return unless preview_image.present?
    errors.add :preview_image, 'should be less than 10MB' if check_image_size(preview_image, 10.megabytes)
    errors.add :preview_image, 'should be more than 600x400px!' if check_image_dimentions(preview_image, 600, 400)
    errors.add :preview_image, 'should match aspect ratio 1.5' unless check_image_aspect_ratio(preview_image, 1.5)
  end

  def validate_mobile_image_size
    return unless mobile_preview_image.present?
    errors.add :mobile_preview_image, 'should be less than 10MB' if check_image_size(mobile_preview_image, 10.megabytes)
    errors.add :mobile_preview_image, 'should be more than 450x300px!' if check_image_dimentions(mobile_preview_image, 450, 300)
    errors.add :mobile_preview_image, 'should match aspect ratio 1.5' unless check_image_aspect_ratio(mobile_preview_image, 1.5)
  end

  def average_score
    # self.study_completions.average(:score)
    total_inc = study_completions.select(:score).map(&:score).compact
    begin
      (total_inc.sum / total_inc.count).floor
    rescue StandardError
      0
    end
  end

  def custom_results_schema
    if json_results_schema.file
      begin
        JSON.parse(json_results_schema.read)
      rescue StandardError
        []
      end
    else
      [] # return an empty array because this will designate a study without custom data
    end
  end

  def custom_results_trials
    custom_results_schema.length
  end

  def custom_results_keys
    custom_results_schema[0]&.keys
  end

  def custom_results_csv_headers
    headers_arr = []
    custom_results_schema.each_with_index do |trial, index|
      trial.keys.each do |key|
        headers_arr << "data.#{index + 1}.#{key}"
      end
    end

    headers_arr
  end

  def set_study_order
    count = Study.count
    self.study_order ||= count + 1
  end

  def self.search_tags(query)
    tags = ActsAsTaggableOn::Tag.where('name LIKE ?', "%#{query}%").limit(10)

    if tags.empty?
      [{ id: "<<<#{query}>>>", name: "New: #{query}" }]
    else
      tags
    end
  end

  def self.find_studies_with_details(user_id = nil)
    Study.left_outer_joins(:study_completions).includes(:creator)
         .select('studies.id, studies.name, studies.created_by,
        studies.created_at,studies.updated_at, COUNT(study_completions.id) as sc_count')
         .where(created_by_condition(user_id)).group('studies.id').order(study_order: :asc)
  end

  def self.get_study_statistics(studies: [])
    statistics_hash = {}
    user_study_hash = UserStudy.select('user_studies.study_id, COUNT(*) AS incomplete_count').group('user_studies.study_id').order(study_id: :asc).index_by(&:study_id)
    study_grouped_study_completions = StudyCompletion.all.group_by(&:study_id)
    study_completion_hash = {}
    study_grouped_study_completions.each do |study_id, study_completions|
      start_count = []
      completion_time = []
      study_completions.each do |study_completion|
        start_count.push(study_completion.start_count || 1)
        completion_time.push(study_completion.completed_on - (study_completion.started_at || (study_completion.completed_on - 10.minutes)))
      end
      study_completion_hash[study_id] = {
        study_id: study_id,
        completed_count: study_completions.count,
        average_start_count: (start_count.sum / start_count.length),
        average_completion_time: (completion_time.sum / completion_time.length)
      }
    end
    # study_completion_hash = StudyCompletion.select('study_id, AVG(start_count) AS average_start_count, COUNT(*) AS completed_count, AVG(AGE(completed_on, started_at)) AS average_completion_time ').group('study_id').order(study_id: :asc).index_by(&:study_id)
    studies.each do |study|
      study_id = study.id
      # Completion ratio in %
      completion_ratio = begin
                           ((study_completion_hash[study_id][:completed_count].to_f * 100) / (study_completion_hash[study_id][:completed_count].to_f + user_study_hash[study_id].incomplete_count.to_f)).round(2)
                         rescue StandardError
                           'N/A'
                         end
      statistics_hash[study.id] = {
        incomplete_count: (begin
                               user_study_hash[study_id].incomplete_count
                           rescue StandardError
                             0
                             end),
        completed_count: (begin
                              study_completion_hash[study_id][:completed_count]
                          rescue StandardError
                            'N/A'
                            end),
        average_completion_time: formatted_completion_time((begin
                                                                study_completion_hash[study_id][:average_completion_time]
                                                            rescue StandardError
                                                              nil
                                                              end)),
        average_start_count: (begin
                                  study_completion_hash[study_id][:average_start_count]
                              rescue StandardError
                                'N/A'
                                end),
        completion_ratio: completion_ratio
      }
    end
    statistics_hash
  end

  def self.general?(study)
    study.is_a?(General)
  end

  def self.ema_daily?(study)
    study.type == EMA_DAILY_TYPE
  end

  def self.ema_weekly?(study)
    study.type == EMA_WEEKLY_TYPE
  end

  # when mobile_js_presentation_url is present then it return false.
  def custom_results?
    mobile_js_presentation_url.blank?
  end

  def self.formatted_completion_time(time_string)
    "#{Regexp.last_match(1)}H:#{Regexp.last_match(2)}M:#{Regexp.last_match(3)}S" if time_string =~ /(\d+):(\d+):(\d+).(\d+)/
  end

  def self.created_by_condition(user_id)
    user_id.present? ? "created_by = #{user_id}" : 'created_by IS NOT NULL'
  end

  def crop_image
    mobile_preview_image.recreate_versions! if mobile_preview_image_changed?
  end

  def check_image_size(image, size)
    image.size > size rescue return false
  end

  def check_image_dimentions(image, width, height)
    image.width < width && image.height < height rescue return false
  end

  def check_image_aspect_ratio(image, aspect_ratio)
    begin
      actual_aspect_ratio = (image.width.to_f / image.height.to_f) 
      aspect_ratio - 0.1 <= actual_aspect_ratio && actual_aspect_ratio <= aspect_ratio + 0.1
    rescue
      return false
    end
  end
  
  def set_default_preview_image
    preview_image = ActionController::Base.helpers.asset_path('/logohead.png') unless preview_image.present?
    mobile_preview_image = ActionController::Base.helpers.asset_path('/logohead.png') unless mobile_preview_image.present?
  end

  def delete_pre_registration_details
    if !pre_registration_required
      self.pre_registration_start_date = nil
      self.start_date = nil
    end
  end

  def self.reject_expired_study(studies)
    studies.reject {|study| study.start_date.present? && !Date.today.between?(study.pre_registration_start_date, study.start_date - 1.day) }
  end

  def self.calculate_total_notifications(study)
    if !Study.general?(study)
      study.frequency*study.number_of_notification
    else 
      0
    end
  end
end