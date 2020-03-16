# == Schema Information
#
# Table name: user_study_pre_registrations
#
#  id               :bigint           not null, primary key
#  user_id          :bigint           not null
#  study_id         :bigint           not null
#  created_at       :datetime         not null
#  updated_at       :datetime         not null
#  reg_date         :date
#  start_time       :time
#  end_time         :time
#  split_start_date :datetime
#  split_end_date   :datetime
#

class UserStudyPreRegistration < ApplicationRecord
  belongs_to :user
  belongs_to :study

  validate :user_specify_time_present
  validate :reg_date_present

  private

  def reg_date_present
    validate_present('reg_date') unless study.pre_registration_required
  end

  def user_specify_time_present
    if study.study_details&.first&.study_group_notifications&.first&.participant_specified
      validate_present('start_time')
      validate_present('end_time')
      validate_split_field if study.split_week
    end
  end

  def validate_split_field
    validate_present('split_start_date')
    validate_present('split_end_date')
  end

  def validate_present(field)
    errors[field.to_sym] << 'is required' if send(field).blank?
  end
end
