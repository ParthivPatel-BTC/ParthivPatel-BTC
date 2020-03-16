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


class FixNotification < StudyGroupNotification
end
