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

class UserNotification < ApplicationRecord
  belongs_to :user
  belongs_to :study
  has_many :reminders, foreign_key: 'notification_parent_id', class_name: 'UserNotification'
  belongs_to :notification_parent, class_name: 'UserNotification', optional: true
end
