# == Schema Information
#
# Table name: feedbacks
#
#  id            :bigint           not null, primary key
#  user_id       :integer
#  email         :string
#  feedback_type :integer
#  content       :text
#  created_at    :datetime         not null
#  updated_at    :datetime         not null
#

class Feedback < ApplicationRecord
  validates_presence_of :content
  enum feedback_type: {default: 0, delete_account: 1, delete_results: 2, delete_account_and_results: 3}

  FEEDBACK_TYPE_HASH = {
    delete_account: {
      key: :delete_account,
      content: 'ACCOUNT DELETED BY USER'
    },
    delete_results: {
      key: :delete_results,
      content: 'STUDY RESULTS DELETED BY USER'
    },
    delete_account_and_results: {
      key: :delete_account_and_results,
      content: 'ACCOUNT AND STUDY RESULTS DELETED BY USER'
    }
  }.freeze

  has_many :study_completions
end
