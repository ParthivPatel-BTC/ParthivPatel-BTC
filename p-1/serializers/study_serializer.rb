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

# serializer for study
class StudySerializer < BaseSerializer
  attributes :id, :name, :start_date, :study_order, :frequency, :description,
             :estimated_completion_time, :type, :pre_registration_start_date,
             :registration_page_description, :number_of_notification,
             :same_study_material, :same_notification, :split_week

  attribute :updated_at do |object|
    object.updated_at.strftime(GlobalConstants::DATE_FORMAT)
  end

  attribute :notification_type do |object|
    object&.notification_type
  end

  attribute :max_score do |object|
    object.max_score&.to_f
  end

  attribute :custom_results do |object|
    object&.custom_results?
  end

  attribute :average_score do |object|
    object&.average_score
  end

  attribute :purpose_of_study do |object|
    object.purpose_of_study&.body.to_s.presence
  end

  attribute :understading_the_results do |object|
    object.understading_the_results&.body.to_s.presence
  end

  attribute :js_presentation_url do |object|
    js_presentation_url = object.mobile_js_presentation_url&.url
    url_to_file_in_utf_format(js_presentation_url) if js_presentation_url.presence
  end

  # attribute :study_css do |object|
  #   study_css = object.css_url&.url
  #   url_to_file_in_utf_format(study_css) if study_css.present?
  # end

  attribute :base64 do |object|
    mobile_small = object.mobile_preview_image&.mobile_small
    if mobile_small.present? && mobile_small&.url.present?
      convert_to_base64(mobile_small&.url, object)
    end
  end

  attribute :preview_image_base64 do |object|
    mobile_thumb = object.mobile_preview_image&.mobile_thumb
    if mobile_thumb.present? && mobile_thumb&.url.present?
      convert_to_base64(mobile_thumb&.url, object)
    end
  end

  attribute :related_research do |object|
    object.related_research&.body.to_s.presence
  end

  attribute :participant_specified do |object|
    object.study_group_notifications&.first&.participant_specified
  end

  attribute :study_details do |study|
    StudyDetailSerializer.new(study.study_details)
  end
end
