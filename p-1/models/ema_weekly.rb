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


class EmaWeekly < EmaDaily
  validate :total_notification, if: :active?

  def delete_past_notification
    if same_notification && (notification_type == StudyGroupNotification::RANDOM_NOTIFICATION)
      study_group_notifications.each_with_index do |notification, index|
        notification.destroy if index > (split_week ? 1 : 0)
      end
    elsif notification_type == StudyGroupNotification::FIX_NOTIFICATION
      study_group_notifications.each do |notification|
        notification.end_time = nil
        notification.participant_specified = false
      end
    end
  end

  private

  def total_notification
    weekly_notification_validate if split_week
  end

  def weekly_notification_validate
    addition_of_notification = 0
    study_group_notifications.each do |notification|
      addition_of_notification += notification.weekly_notifications
    end
    unless addition_of_notification == number_of_notification
      errors.add :number_of_notification, '^Split the week number of notifications should SUM up to the total number of notifications for a week'
    end
  end
end
