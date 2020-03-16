require 'test_helper'

class StudyControllerTest < ActionDispatch::IntegrationTest

  # consent is one of the more complex items in this project. I have deemed integration test
  # would help me sleep better at night.


  # test "the truth" do
  #   assert true
  # end

  setup do
    @study = create(:study)
  end

  test "should redirect unconsented user to consent page" do
    get study_path(@study)
    assert_redirected_to consent_index_url(study_url: study_path(@study))
  end

  test "going to the sign up page should redirect you to pre-registration consent page" do
    get new_user_registration_url

    assert_redirected_to pre_registration_consent_index_url
  end

  test "should allow logged in, consented user to survey show" do
    sign_in create(:user, consent: true)

    get study_path(@study)
    assert_response :success
  end
end

#   test "should create contact" do
#     assert_difference('Contact.count') do
#       post contacts_url, params: { contact: {  } }
#     end

#     assert_redirected_to contact_url(Contact.last)
#   end