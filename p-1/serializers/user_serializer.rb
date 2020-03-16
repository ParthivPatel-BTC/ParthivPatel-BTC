# == Schema Information
#
# Table name: users
#
#  id                     :bigint           not null, primary key
#  email                  :text             default(""), not null
#  encrypted_password     :string           default(""), not null
#  reset_password_token   :text
#  reset_password_sent_at :datetime
#  remember_created_at    :datetime
#  sign_in_count          :integer          default(0), not null
#  current_sign_in_at     :datetime
#  last_sign_in_at        :datetime
#  current_sign_in_ip     :inet
#  last_sign_in_ip        :inet
#  created_at             :datetime         not null
#  updated_at             :datetime         not null
#  provider               :string
#  uid                    :string
#  consent                :boolean
#  study_completion_id    :integer
#  confirmation_token     :string
#  confirmed_at           :datetime
#  confirmation_sent_at   :datetime
#  role                   :text
#  user_session_id        :string
#  token                  :text
#  device_id              :text
#

class UserSerializer < BaseSerializer
  attributes :id, :email, :token
end
