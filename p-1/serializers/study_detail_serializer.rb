# frozen_string_literal: true

# == Schema Information
#
# Table name: study_details
#
#  id                      :bigint           not null, primary key
#  study_id                :bigint
#  embed_code              :string
#  mobile_embed_code       :string
#  css_url                 :string
#  end_date                :datetime
#  number_of_notifications :integer
#  created_at              :datetime         not null
#  updated_at              :datetime         not null
#


# serializer for study
class StudyDetailSerializer < BaseSerializer
  attributes :end_date

  attribute :embed_code do |object|
    embed_code = object.mobile_embed_code&.url
    url_to_file_in_utf_format(embed_code) if embed_code.presence
  end

  attribute :css_url do |object|
    css_url = object.css_url&.url
    url_to_file_in_utf_format(css_url) if css_url.presence
  end

  attribute :study_group_notifications do |detail|
    StudyGroupNotificationSerializer.new(detail.study_group_notifications)
  end
end
