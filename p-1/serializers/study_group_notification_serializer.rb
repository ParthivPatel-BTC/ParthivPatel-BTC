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


# serializer for study
class StudyGroupNotificationSerializer < BaseSerializer

  attribute :start_time do |object|
    "#{data(object)}T#{time(object.start_time)}"
  end

  attribute :end_time do |object|
    "#{data(object)}T#{time(object.end_time)}"
  end

  def self.data(start_date)
    start_date.study_detail.study.start_date&.strftime(GlobalConstants::DATE_ONLY_YMD)
  end

  def self.time(time)
    time&.strftime(GlobalConstants::TIME_FORMAT)
  end
end
