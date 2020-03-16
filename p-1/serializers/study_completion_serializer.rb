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


# serializer for feedback
class StudyCompletionSerializer < BaseSerializer
  attributes :id, :study_id, :score, :notification

  attribute :completed_on do |object|
    object.completed_on&.strftime(GlobalConstants::DATE_FORMAT)
  end

  attribute :score do |object|
    object.graph_data_mobile[:score]
  end

  attribute :score_pos do |object|
    object.graph_data_mobile[:score_pos]
  end

  attribute :average_score do |object|
    object.graph_data_mobile[:average_score]
  end

  attribute :average_pos do |object|
    object.graph_data_mobile[:average_pos]
  end

  attribute :max_score do |object|
    object.graph_data_mobile[:max_score]
  end

  attribute :left_density do |object|
    object.graph_data_mobile[:left_density]
  end

  attribute :right_density do |object|
    object.graph_data_mobile[:right_density]
  end

  attribute :name do |object|
    object.study_data.name
  end

  attribute :custom_study_results do |object|
    total_notification = Study.calculate_total_notifications(object.study)
    if !Study.general?(object.study) and (total_notification.to_i == object.notification.to_i)
      StudyCompletion.EMA_custom_results(user_id: object.user_id, study_id: object.study_id) 
    else 
      object.custom_study_results
    end
  end

  attribute :custom_results do |object|
    object.study_data&.custom_results?
  end

  attribute :js_presentation_url do |object|
    js_presentation_url = object.study_data&.mobile_js_presentation_url&.url
    url_to_file_in_utf_format(js_presentation_url) if js_presentation_url.presence
  end

  attribute :description do |object|
    object.study_data&.description
  end

  attribute :base64 do |object|
    mobile_medium = object.study_data&.mobile_preview_image&.mobile_medium
    if mobile_medium.present? && mobile_medium&.url.present?
      convert_to_base64(mobile_medium&.url, object)
    end
  end

  attribute :purpose_of_study do |object|
    object.study_data.purpose_of_study&.body.to_s.presence
  end

  attribute :related_research do |object|
    object.study_data.related_research&.body.to_s.presence
  end

  attribute :understading_the_results do |object|
    object.study_data.understading_the_results&.body.to_s.presence
  end

  attribute :type do |object|
    object.study_data.type
  end

  attribute :ema_result do |object|
    if !Study.general?(object.study) and (object.study.study_group_notifications.count.to_i == object.notification.to_i)
      StudyCompletion.EMA_custom_results(user_id: object.user_id, study_id: object.study_id) 
    else 
      nil
    end
  end
end