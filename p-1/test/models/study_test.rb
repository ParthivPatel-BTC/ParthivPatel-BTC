require 'test_helper'

class StudyTest < ActiveSupport::TestCase

  test '#study_completions' do
    # downloading one study, all results
    study = create(:study)
    study_not_downloaded = create(:study)
    study_completion1 = create(:study_completion, study_id: study.id, user_id: 1)
    study_completion2 = create(:study_completion, study_id: study.id, user_id: 2)
    study_completion3 = create(:study_completion, study_id: study.id, user_id: 3)
    study_completion4 = create(:study_completion, study_id: study_not_downloaded.id, user_id: 4)

    assert_includes study.study_completions, study_completion1
    assert_includes study.study_completions, study_completion2
    assert_includes study.study_completions, study_completion3
    refute_includes study.study_completions, study_completion4
  end


  describe '#study_completions.most_recent_completions' do
    it "assets first completion is NOT included when a user completes the same study twice" do
      study = create(:study)
      study_completion = create(:study_completion, study_id: study.id, user_id: 1)
      sleep(1)
      study_completion2 = create(:study_completion, study_id: study.id, user_id: 1)


      refute_includes study.study_completions.most_recent_study_completions, study_completion
      assert_includes study.study_completions.most_recent_study_completions, study_completion2
    end

    it "asserts that multiple users most recent completions are included" do
      study = create(:study, id: 1)
      study_completion = create(:study_completion, study_id: study.id, user_id: 1)
      sleep(1)
      study_completion2 = create(:study_completion, study_id: study.id, user_id: 1)
      other_study_completion = create(:study_completion, study_id: study.id, user_id: 2)

      refute_includes study.study_completions.most_recent_study_completions, study_completion
      assert_includes study.study_completions.most_recent_study_completions, study_completion2
      assert_includes study.study_completions.most_recent_study_completions, other_study_completion
    end

    it "asserts that logged out users will NOT be included because we cannot figure their most recent completion" do
      study = create(:study, id: 1)
      study_completion = create(:study_completion, study_id: study.id, user_id: nil)

      refute_includes study.study_completions.most_recent_study_completions, study_completion
    end
  end

 describe '#study_completions.all_first_time_completions' do
    it "asserts first completion is included" do
      study = create(:study, id: 1)
      completion = create(:study_completion, study_id: study.id, user_id: 2)
      sleep(1)
      completion2 = create(:study_completion, study_id: study.id, user_id: 2)

      assert_includes study.study_completions.all_first_time_completions, completion
      refute_includes study.study_completions.all_first_time_completions, completion2
    end

    it "asserts that multiple users first taken completions are included" do
      study = create(:study, id: 1)
      comp = create(:study_completion, study_id: study.id, user_id: 2)
      sleep(1)
      comp2 = create(:study_completion, study_id: study.id, user_id: 2)
      other_completion = create(:study_completion, study_id: study.id, user_id: 3)

      assert_includes study.study_completions.all_first_time_completions, comp
      refute_includes study.study_completions.all_first_time_completions, comp2
      assert_includes study.study_completions.all_first_time_completions, other_completion
    end

    # it "asserts that logged out users are included, if it is their first time taking the survey" do
    #   study = create(:study, id: 1)
    #   completion = create(:logged_out_study_completion, study_id: study.id, user_id: nil, taken_survey_before: false)


    #   assert_includes study.study_completions.all_first_time_completions, completion
    # end

    # it "asserts that logged out users are excluded when it is NOT their first time taking the survey" do
    #   study = create(:study, id: 1)
    #   completion = create(:logged_out_study_completion, study_id: study.id, user_id: nil, taken_survey_before: true)

    #   refute_includes study.study_completions.all_first_time_completions, completion
    # end

    # it "excludes users when the end_of_study association doesnt exist"
 end


end


