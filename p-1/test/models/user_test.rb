require 'test_helper'

class UserTest < ActiveSupport::TestCase

  def setup
    @user_without_consent = create(:user, consent: false)
  end

  test '#set_consent' do
    assert_equal @user_without_consent.consent, false

    @user_without_consent.set_consent

    assert_equal @user_without_consent.consent, true    
  end
end
