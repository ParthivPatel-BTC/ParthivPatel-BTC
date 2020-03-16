# frozen_string_literal: true

# == Schema Information
#
# Table name: study_group_notifications
#
#  id                    :bigint           not null, primary key
#  study_detail_id       :bigint           not null
#  study_id              :bigint
#  type                  :string
#  start_time            :time
#  end_time              :time
#  number_of_reminders   :integer
#  reminder_spacing      :integer
#  participant_specified :boolean          default(FALSE)
#  created_at            :datetime         not null
#  updated_at            :datetime         not null
#  week_days             :string
#  weekly_notifications  :integer
#

class StudyGroupNotification < ApplicationRecord
  default_scope { order(:created_at) }
  belongs_to :study_detail
  belongs_to :study, optional: true
  NUMBER_OF_WEED_DAY = { mon: 7, tue: 1, wed: 2, thu: 3,
                         fri: 4, sat: 5, sun: 6 }.freeze
  RANDOM_NOTIFICATION = 'RandomNotification'
  FIX_NOTIFICATION = 'FixNotification'
  NOTIFICATION_TYPE = { RandomNotification: 'Random Notification Schedule',
                        FixNotification: 'Fixed Notification Schedule' }.freeze
  validates :number_of_reminders, numericality: { only_integer: true, less_than_or_equal_to: 3 }, allow_nil: true, if: :study_active?
  validates :start_time, presence: true, if: :study_active?
  validates :type, presence: true
  validate :study_end_time, if: :published_and_random_notification?
  validate :reminder_spacing_check, if: :study_active?
  validate :validate_week_days, if: :published_and_ema_weekly
  validates :weekly_notifications, presence: true, if: :split_week_on
  before_create :set_study_id

  store :week_days, accessors: %i[sun mon tue wed thu fri sat]

  private

  def validate_week_days
    if week_days.select{ |week_days, value| week_days if value == 'true' }.count.zero?
      errors.add :week_days, '^please select at least one week day'
    end
  end

  def split_week_on
    published_and_ema_weekly && study_detail.study.split_week
  end

  def reminder_spacing_check
    return unless number_of_reminders.present?

    errors.add :reminder_spacing, 'should be present.' unless reminder_spacing.present?
  end

  def published_and_ema_weekly
    study_active? && (study_detail.study.type == Study::EMA_WEEKLY_TYPE)
  end

  def published_and_random_notification?
    study_active? && type == RANDOM_NOTIFICATION
  end

  def study_active?
    study_detail.study.active?
  end

  def study_end_time
    errors[:end_time] << "can't be blank" if end_time.blank?
    errors[:end_time] << 'must be greater than start time' if end_time.present? && start_time.present? && end_time <= start_time
  end

  def set_study_id
    self.study_id = study_detail.study_id
  end
end
