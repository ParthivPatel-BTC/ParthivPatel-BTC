# == Schema Information
#
# Table name: contacts
#
#  id                 :bigint           not null, primary key
#  first_name         :text
#  last_name          :text
#  email_address      :text
#  questions_comments :text
#  created_at         :datetime         not null
#  updated_at         :datetime         not null
#

class Contact < ApplicationRecord
  validates :email_address, presence: true
  validate :question_comments_presence
  validates :email_address, format: { with: /\A([^@\s]+)@((?:[-a-z0-9]+\.)+[a-z]{2,})\z/i }

  crypt_keeper :first_name, :last_name, :email_address, :questions_comments,
               encryptor: :active_support,
               key: ENV['CONTACT_ENCRYPTION_KEY'], salt: ENV['CONTACT_ENCRYPTION_SALT']

  def question_comments_presence
    if self.attributes.values.all? &:blank?
      errors.add(:questions_comments, "can't be blank")
    end
  end
end
