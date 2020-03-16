# frozen_string_literal: true

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


# serializer for feedback
class FeedbackSerializer < BaseSerializer
  attributes :id, :user_id, :email, :feedback_type, :content
end
