# == Schema Information
#
# Table name: user_studies
#
#  id              :bigint           not null, primary key
#  study_id        :bigint
#  user_id         :bigint
#  started_at      :text
#  user_session_id :string
#  start_count     :text
#  feedback_id     :integer
#

class UserStudy < ApplicationRecord
  belongs_to :study
  belongs_to :user
  belongs_to :feedback, optional: true

  crypt_keeper :started_at, :start_count,
               encryptor: :active_support,
               key: ENV['USER_STUDY_ENCRYPTION_KEY'], salt: ENV['USER_STUDY_ENCRYPTION_SALT']
  before_save :set_default_start_count

  def started_at
    read_attribute(:started_at).try(:in_time_zone)
  end

  def set_default_start_count
    self.start_count = 1 if start_count.blank?
  end
 
  def start_count
    read_attribute(:start_count).try(:to_i)
  end
end
