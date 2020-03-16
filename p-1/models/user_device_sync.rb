# == Schema Information
#
# Table name: user_device_syncs
#
#  id           :bigint           not null, primary key
#  user_id      :bigint           not null
#  device_id    :string
#  last_sync_at :string
#  created_at   :datetime         not null
#  updated_at   :datetime         not null
#

class UserDeviceSync < ApplicationRecord
  belongs_to :user
end
