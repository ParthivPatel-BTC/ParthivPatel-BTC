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

class EmaDaily < Study
  before_create :create_study_detail

  validate :frequency_validate, if: :active?
  validate :number_of_notification_validate, if: :active?
  before_update :delete_past_notification
  before_update :delete_random_fields

  # create empty entry for form so in edit case form render as we want.
  def create_study_detail
    if same_study_material
      check_before_create
    elsif same_notification
      return if study_details.size == number_of_notification

      (number_of_notification - study_details.size).times do
        build_study_detail
      end
    end
  end
  
  # build proper object of study using very first form of study creation (study_type.html).
  def build_related_entities(number_of_days: 1, notifications_per_day: 1, same_study_material: false, same_notification_schedule: false)
    boolean_same_study_material = ActiveModel::Type::Boolean.new.cast(same_study_material)
    boolean_same_notification_schedule = ActiveModel::Type::Boolean.new.cast(same_notification_schedule)

    if boolean_same_study_material
      ema_first_two_case(notifications_per_day)
    elsif boolean_same_notification_schedule
      notifications_per_day.to_i.times do
        ema_first_two_case(notifications_per_day)
      end
    else
      (number_of_days.to_i * notifications_per_day.to_i).times do
        study_detail = study_details.build
        notification = study_detail.study_group_notifications.build
        notification.type = StudyGroupNotification::RANDOM_NOTIFICATION
      end
    end
  end

  def notification_type
    study_details&.first&.study_group_notifications&.first&.type
  end

  private

  def frequency_validate
    validate_with_message('frequency', 'must be in between 1 to 30', 1..30) unless same_study_material
  end

  def number_of_notification_validate
    validate_with_message('number_of_notification', 'must be in between 1 to 10', 1..10)
  end

  def validate_with_message(column_name, message, in_between)
    errors[column_name.to_sym] << message unless in_between.include? send(column_name)
  end

  def ema_first_two_case(notifications_per_day)
    study_detail = study_details.build
    notifications_per_day.to_i.times do
      notification = study_detail.study_group_notifications.build
      notification.type = StudyGroupNotification::RANDOM_NOTIFICATION
    end
  end

  def check_before_create
    build_study_detail if study_details.size.zero?
  end

  def build_study_detail
    study_details.build
  end

  def delete_random_fields
    return if notification_type == StudyGroupNotification::RANDOM_NOTIFICATION

    study_details.each do |study_detail|
      study_detail.study_group_notifications.each do |notification|
        notification.end_time = nil
        notification.participant_specified = false
      end
    end
  end

  def delete_past_notification
    if same_notification && (notification_type == StudyGroupNotification::RANDOM_NOTIFICATION)
      study_details.each do |study_detail|
        study_detail.study_group_notifications.each_with_index do |notification, index|
          notification.destroy unless index.zero?

        end
      end
    end
  end
end
