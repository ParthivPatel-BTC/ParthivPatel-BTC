require 'test_helper'

class DownloadTest < ActiveSupport::TestCase
  describe '#users_who_completed_all_studies(study_ids)' do
    it "accepts an array of study_ids" do
      study1 = create(:study)
      study2 = create(:study)
      study_ids = [study1.id, study2.id]
      create(:study_completion, study_id: study1.id)
      create(:study_completion, study_id: study2.id)
      download = create(:download, download_type:"All", study_ids: study_ids)

      # if this stops working, it will throw an error, that seems like 75% of the way there, better than 0%.
      download.users_who_completed_all_studies
    end

    it "returns an array of user_ids" do
      study1 = create(:study)
      study_ids = [study1.id]
      user = create(:user)
      user_who_did_not_complete_the_study = create(:user)

      study_completion = create(:study_completion, user_id: user.id, study_id: study1.id)
      download = create(:download, download_type:"All", study_ids: study_ids)

      user_ids = download.users_who_completed_all_studies

      assert_equal(user_ids, [user.id])
      refute_includes(user_ids, user_who_did_not_complete_the_study.id)
    end

    it "returns all users who completed all studies" do
      study1 = create(:study)
      study2 = create(:study)
      study_ids = [study1.id, study2.id]
      user = create(:user)
      user_who_did_not_complete_both_studies = create(:user)
      download = create(:download, download_type:"All", study_ids: study_ids)

      create(:study_completion, user_id: user.id, study_id: study1.id)
      create(:study_completion, user_id: user.id, study_id: study2.id)
      create(:study_completion, user_id: user_who_did_not_complete_both_studies.id, study_id: study2.id)

      user_ids = download.users_who_completed_all_studies

      assert_equal(user_ids, [user.id])
      assert_includes(user_ids, user.id)
      refute_includes(user_ids, user_who_did_not_complete_both_studies.id)
    end
  end

  describe "#download_study_completions" do
    it "is a significant portion of this project" do
      assert_equal true, true
    end

    it "has 6 download cases" do
      "in All Cases"
      # add demographic information as the last columns in the export, finding it will be the tricky part
        # demographic info is located: Logged in users -> user, logged out -> survey_completion
      # csv export headers: user_information, study_completion(s), demographic information
      #                     => user_id
      # headers for study_completion
      # id: integer, user_id: integer, study_id: integer, completed_on: datetime, score: decimal, created_at: datetime, updated_at: datetime, custom_study_results: json, similar_experiment: string, technical_problems: string, did_you_cheat: string, people_in_room: integer, comments: string, taken_survey_before: boolean
      # headers for demographic information
      # id: integer, user_id: integer, gender: string, ethnicity: string, total_household_income: integer, political_on_social: string, political_on_economic: string, english_as_primary: boolean, birth_year: integer, highest_level_of_education: string, created_at: datetime, updated_at: datetime, study_completion_id: integer
      # do demographic information at the beginning


      "Download Single Study, All"
      build(:download, study_ids: ["1"], download_type: "All")
      # Logged out user data is INCLUDED
      # Each Completion is its own row on the CSV
      # user_id, demographic_information, study_completion1, study_completion2
      # gender, ethnicity, total_household_income, political_on_social, english_as_primary, birth_year, highest_level_of_education

      "Download Single Study, Most Recent"
      build(:download, study_ids: ["1"], download_type: "Most Recent")
      # Logged out user data is included because if it is your first taken, it is also your most recent
      # Each Completion is its own row on the CSV ??? ... each user will only have 1 completion...

      "Download Single Study, First Taken"
      build(:download, study_ids: ["1"], download_type: "First Taken")
      # Logged out user data is INCLUDED, when indicated they have not taken this survey before
      # Each Completion is its own row on the CSV ???

      "Download Multiple Studies, All"
      build(:download, study_ids: ["1", "2"], download_type: "All")
      # Logged out user data is EXCLUDED (because we can't track users across multiple surveys)
      # Each Completion is its own row on the CSV

      "Download Multiple Studies, Most Recent"
      build(:download, study_ids: ["1", "2"], download_type: "Most Recent")
      # Logged out user data is EXCLUDED (because we can't track users across multiple surveys)
      # Each USER is its own row on the CSV

      "Download Multiple Studies, First Taken"
      build(:download, study_ids: ["1", "2", "3"], download_type: "First Taken")
      # Logged out user data is EXCLUDED (because we can't track users across multiple surveys)
      # Each USER is its own row on the CSV
    end
  end

  describe "#download_study_completions SINGLE STUDY, ALL" do
    it "includes logged out user data as well as logged in user data" do
      study = create(:study)
      other_study = create(:study)
      user = create(:user)
      logged_out_study_completion = create(:study_completion, study_id: study.id, user_id: nil)
      logged_in_study_completion = create(:study_completion, study_id: study.id, user_id: user.id)
      other_study_completion = create(:study_completion, study_id: other_study.id, user_id: user.id)

      download = build(:download, study_ids: [study.id], download_type: "All")

      completions = download.download_study_completions

      assert_includes(completions, logged_out_study_completion)
      assert_includes(completions, logged_in_study_completion)
      refute_includes(completions, other_study_completion)
    end
  end

  describe "#download_study_completions SINGLE STUDY, Most Recent" do
    it "shows only most recent taken study for logged in users" do
      study = create(:study)
      other_study = create(:study)
      user = create(:user)
      first_study_completion = create(:study_completion, study_id: study.id, user_id: user.id)
      sleep(1)
      second_study_completion = create(:study_completion, study_id: study.id, user_id: user.id)
      sleep(1)
      other_study_completion = create(:study_completion, study_id: other_study.id, user_id: user.id)
      third_study_completion = create(:study_completion, study_id: study.id, user_id: user.id)
      download = build(:download, study_ids: [study.id], download_type: "Most Recent")

      completions = download.download_study_completions

      refute_includes(completions, first_study_completion)
      refute_includes(completions, second_study_completion)
      assert_includes(completions, third_study_completion)
      refute_includes(completions, other_study_completion)
    end

    it "includes logged out user data where indicated that it is first attempt" do
      # this seems counter intuitive, but we assume if the person indicates it is their first time, it is also their most recent.
      study = create(:study)
      other_study = create(:study)
      user = create(:user)
      logged_out_study_completion_first_time = create(:study_completion, study_id: study.id, user_id: nil, taken_survey_before: false)
      logged_out_study_completion_NOT_first_time = create(:study_completion, study_id: study.id, user_id: nil, taken_survey_before: true)

      download = build(:download, study_ids: [study.id], download_type: "Most Recent")
      completions = download.download_study_completions

      assert_includes(completions, logged_out_study_completion_first_time)
      refute_includes(completions, logged_out_study_completion_NOT_first_time)
    end
  end

  describe "#download_study_completions SINGLE STUDY, First Taken" do
    it "includes logged out user data where indicated that it is first attempt" do
      study = create(:study)
      other_study = create(:study)
      user = create(:user)
      logged_out_study_completion_first_time = create(:study_completion, study_id: study.id, user_id: nil, taken_survey_before: false)
      logged_out_study_completion_NOT_first_time = create(:study_completion, study_id: study.id, user_id: nil, taken_survey_before: true)

      download = build(:download, study_ids: [study.id], download_type: "First Taken")
      completions = download.download_study_completions

      assert_includes(completions, logged_out_study_completion_first_time)
      refute_includes(completions, logged_out_study_completion_NOT_first_time)
    end

    it "includes first attempts of logged in users" do
      study = create(:study)
      user = create(:user)

      first_study_completion = create(:study_completion, study_id: study.id, user_id: user.id)
      sleep(1)
      second_study_completion = create(:study_completion, study_id: study.id, user_id: user.id)

      download = build(:download, study_ids: [study.id], download_type: "First Taken")
      completions = download.download_study_completions

      assert_includes(completions, first_study_completion)
      refute_includes(completions, second_study_completion)
    end

    it "excludes other studies" do
      study = create(:study)
      other_study = create(:study)
      user = create(:user)

      first_study_completion = create(:study_completion, study_id: study.id, user_id: user.id)
      other_study_completion = create(:study_completion, study_id: other_study.id, user_id: user.id)

      download = build(:download, study_ids: [study.id], download_type: "First Taken")
      completions = download.download_study_completions

      assert_includes(completions, first_study_completion)
      refute_includes(completions, other_study_completion)
    end
  end

  describe "#download_study_completions MULTIPLE STUDIES, ALL" do
    it "ONLY includes users who have taken ALL STUDIES" do
      study = create(:study)
      study2 = create(:study)
      user = create(:user)
      user2 = create(:user)

      first_study_completion = create(:study_completion, study_id: study.id, user_id: user.id)
      second_study_completion = create(:study_completion, study_id: study2.id, user_id: user.id)

      first_study_completion_user2 = create(:study_completion, study_id: study.id, user_id: user2.id)


      download = build(:download, study_ids: [study.id, study2.id], download_type: "All")
      completions = download.download_study_completions

      assert_includes(completions, first_study_completion)
      assert_includes(completions, second_study_completion)
      refute_includes(completions, first_study_completion_user2)
    end

    it "excludes logged out user data" do
      study = create(:study)
      study2 = create(:study)

      first_study_completion = create(:study_completion, study_id: study.id, user_id: nil)
      second_study_completion = create(:study_completion, study_id: study2.id, user_id: nil)

      download = build(:download, study_ids: [study.id, study2.id], download_type: "All")
      completions = download.download_study_completions

      refute_includes(completions, first_study_completion)
      refute_includes(completions, second_study_completion)
    end
  end

  describe "#download_study_completions MULTIPLE STUDIES, MOST RECENT" do
    it "includes most recent studies only" do
      study = create(:study)
      study2 = create(:study)
      user = create(:user)

      first_first_study_completion = create(:study_completion, study_id: study.id, user_id: user.id)
      sleep(1)
      most_recent_first_study_completion = create(:study_completion, study_id: study.id, user_id: user.id)

      most_recent_second_study_completion = create(:study_completion, study_id: study2.id, user_id: user.id)

      download = build(:download, study_ids: [study.id, study2.id], download_type: "Most Recent")
      completions = download.download_study_completions

      assert_includes(completions, most_recent_first_study_completion)
      assert_includes(completions, most_recent_second_study_completion)
      refute_includes(completions, first_first_study_completion)
    end

    it "STRESS TEST: includes most recent studies from multiple users with more than 2 studies" do
      study = create(:study)
      study2 = create(:study)
      # study3 = create(:study)
      user = create(:user)
      user2 = create(:user)
      user3 = create(:user)


      first_completion_u1 = create(:study_completion, study_id: study.id, user_id: user.id)
      first_completion_u2 = create(:study_completion, study_id: study.id, user_id: user2.id)
      first_completion_u3 = create(:study_completion, study_id: study.id, user_id: user3.id)
      sleep(1)
      second_completion_u1 = create(:study_completion, study_id: study.id, user_id: user.id)
      second_completion_u2 = create(:study_completion, study_id: study.id, user_id: user2.id)
      second_completion_u3 = create(:study_completion, study_id: study.id, user_id: user3.id)

      other_study_completion_u1 = create(:study_completion, study_id: study2.id, user_id: user.id)
      other_study_completion_u2 = create(:study_completion, study_id: study2.id, user_id: user2.id)

      download = build(:download, study_ids: [study.id, study2.id], download_type: "Most Recent")
      completions = download.download_study_completions


      refute_includes(completions, first_completion_u1)
      refute_includes(completions, first_completion_u2)
      refute_includes(completions, first_completion_u3)
      assert_includes(completions, second_completion_u1)
      assert_includes(completions, second_completion_u2)
      refute_includes(completions, second_completion_u3) # user didn't take all studies
      assert_includes(completions, other_study_completion_u1)
      assert_includes(completions, other_study_completion_u2)
    end
  end

  describe "#download_study_completions MULTIPLE STUDIES, FIRST TAKEN" do
    it "includes first taken studies only" do
      study = create(:study)
      study2 = create(:study)
      user = create(:user)

      first_first_study_completion = create(:study_completion, study_id: study.id, user_id: user.id)
      sleep(1)
      most_recent_first_study_completion = create(:study_completion, study_id: study.id, user_id: user.id)

      first_taken_second_study_completion = create(:study_completion, study_id: study2.id, user_id: user.id)

      download = build(:download, study_ids: [study.id, study2.id], download_type: "First Taken")
      completions = download.download_study_completions

      refute_includes(completions, most_recent_first_study_completion)
      assert_includes(completions, first_taken_second_study_completion)
      assert_includes(completions, first_first_study_completion)
    end

    it "STRESS TEST: includes first taken studies from multiple users with more than 2 studies" do
      study = create(:study)
      study2 = create(:study)

      user = create(:user)
      user2 = create(:user)
      user3 = create(:user)


      first_completion_u1 = create(:study_completion, study_id: study.id, user_id: user.id)
      first_completion_u2 = create(:study_completion, study_id: study.id, user_id: user2.id)
      first_completion_u3 = create(:study_completion, study_id: study.id, user_id: user3.id)
      sleep(1)
      second_completion_u1 = create(:study_completion, study_id: study.id, user_id: user.id)
      second_completion_u2 = create(:study_completion, study_id: study.id, user_id: user2.id)
      second_completion_u3 = create(:study_completion, study_id: study.id, user_id: user3.id)

      other_study_completion_u1 = create(:study_completion, study_id: study2.id, user_id: user.id)
      other_study_completion_u2 = create(:study_completion, study_id: study2.id, user_id: user2.id)

      download = build(:download, study_ids: [study.id, study2.id], download_type: "First Taken")
      completions = download.download_study_completions

      assert_includes(completions, first_completion_u1)
      assert_includes(completions, first_completion_u2)
      refute_includes(completions, first_completion_u3) # user didn't take all studies
      refute_includes(completions, second_completion_u1)
      refute_includes(completions, second_completion_u2)
      refute_includes(completions, second_completion_u3) # user didn't take all studies
      assert_includes(completions, other_study_completion_u1)
      assert_includes(completions, other_study_completion_u2)
    end
  end

  describe "#to_csv download Single Study, ALL entries" do
    # need to test with and without demographic information
    # arf, good luck.
  end
end
