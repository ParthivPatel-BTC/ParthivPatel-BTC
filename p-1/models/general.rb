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


# General study model
class General < Study

  before_create :create_study_detail

  def build_related_entities
    study_details.build
  end

  def create_study_detail
    build_related_entities if study_details.size.zero?
  end

  def notification_type
    nil
  end
end
