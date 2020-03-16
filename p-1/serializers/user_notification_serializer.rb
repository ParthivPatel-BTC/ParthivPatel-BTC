# frozen_string_literal: true

# == Schema Information
#
# Table name: user_notifications
#
#  id                     :bigint           not null, primary key
#  user_id                :bigint           not null
#  study_id               :bigint           not null
#  notification_time      :datetime
#  study_detail_index     :integer
#  reminder               :boolean
#  notification_parent_id :integer
#  created_at             :datetime         not null
#  updated_at             :datetime         not null
#  number                 :string
#


class UserNotificationSerializer < BaseSerializer
  attributes :id,
             :study_id,
             :study_detail_index,
             :reminder,
             :notification_parent_id,
             :number
  
  attribute :notification_time do |object|
    object.notification_time&.strftime(GlobalConstants::TIME_WITHOUT_ZONE)
  end
  attribute :study_name do |object|
    Study.find_by(id: object.study_id)&.name
  end
end
