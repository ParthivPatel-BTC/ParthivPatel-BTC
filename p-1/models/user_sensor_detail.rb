class UserSensorDetail < ApplicationRecord
  belongs_to :user

  store :sensor, accessors: %i[accelerometer ambient_light]
end
