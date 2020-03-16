# == Schema Information
#
# Table name: downloads
#
#  id            :bigint           not null, primary key
#  study_ids     :text             default([]), is an Array
#  download_type :string
#  created_at    :datetime         not null
#  updated_at    :datetime         not null
#

class Download < ApplicationRecord
  validates_presence_of :download_type

  DEMOGRAPHIC_HEADERS = %w(gender ethnicity ethnicity_description total_household_income political_on_social political_on_economic number_of_people_in_household language other_language birth_year highest_level_of_education).freeze
  STUDY_COMPLETION_HEADERS = %w(id user_id study_id completed_on score similar_experiment technical_problems technical_problem_description did_you_cheat cheating_description people_in_room comments taken_survey_before started_at start_count).freeze
  # download_types: "All", "Most Recent", "First Taken"
  def users_who_completed_all_studies
    @downloaded_studies = Study.find(self.study_ids)

    user_arr = []
    @downloaded_studies.each do |study|
      user_arr.push(study.study_completions.pluck(:user_id).uniq)
    end

    ## SELECT THE COMMON VALUES OF ALL INTERIOR ARRAYS
    user_ids_and_nil = user_arr.reduce { |a, b| a & b }


    ## THIS COMMAND GETS RID OF ALL LOGGED OUT USER SURVEY DATA -- could be interesting to see if its use can dry up code
    user_ids_who_completed_all_studies = user_ids_and_nil.grep(Integer)

    user_ids_who_completed_all_studies
  end

  def download_study_completions
    if self.is_single_study_download?
      download_single_study_completions
    else
      download_multiple_study_completions
    end
  end

  def download_single_study_completions
    if self.download_type == "All"
      completions = StudyCompletion.where(study_id: self.study_ids)
    elsif self.download_type == "Most Recent"
      completions = Study.find(self.study_ids[0]).study_completions.most_recent_study_completions
    elsif self.download_type == "First Taken"
      completions = Study.find(self.study_ids[0]).study_completions.all_first_time_completions
    end
  end

  def download_multiple_study_completions
    user_ids_completing_all_studies = users_who_completed_all_studies
    if self.download_type == "All"
      completions = StudyCompletion.where(study_id: self.study_ids, user_id: user_ids_completing_all_studies)
    elsif self.download_type == "Most Recent"
      # loop through each study, then each user completing all studies, find their most recent survey, save the id and find it later.
      most_recent_completion_ids = []
      self.study_ids.each do |study_id|
        user_ids_completing_all_studies.each do |user_id|
          most_recent_completion_ids << StudyCompletion.where(study_id: study_id, user_id: user_id).select("DISTINCT ON(user_id) *").order("user_id, created_at DESC")[0].id
        end
      end
      completions = StudyCompletion.where(id: most_recent_completion_ids)
    elsif self.download_type == "First Taken"
      most_recent_completion_ids = []
      self.study_ids.each do |study_id|
        user_ids_completing_all_studies.each do |user_id|
          most_recent_completion_ids << StudyCompletion.where(study_id: study_id, user_id: user_id).select("DISTINCT ON(user_id) *").order("user_id, created_at ASC")[0].id
        end
      end
      completions = StudyCompletion.where(id: most_recent_completion_ids)
    end
  end

  def csv_headers
    csv_headers_arr = []
    csv_headers_arr << self.demographic_headers
    self.sorted_study_ids.each do |study|
      @study = Study.find(study)
      csv_headers_arr << STUDY_COMPLETION_HEADERS
      csv_headers_arr << @study.custom_results_csv_headers
    end

    csv_headers_arr.flatten!
  end

  def demographic_headers
    DEMOGRAPHIC_HEADERS
  end

  def demographic_information_array(study_completion)
    if study_completion.demographic
      study_completion.demographic.downloadable_attributes_values
    elsif study_completion.user && study_completion.user.demographic
      study_completion.user.demographic.downloadable_attributes_values
    elsif study_completion.user_id && Demographic.find_by(user_id: study_completion.user_id) # this if block inputs the demographic information into the download EVEN WHEN the user deletes their account
      Demographic.find_by(user_id: study_completion.user_id).downloadable_attributes_values
    else
      Array.new(demographic_headers.length)
    end
  end

  def generate_single_study_download_csv(data)
    CSV.generate do |csv|
      csv << self.csv_headers
      @data.each do |study_completion|
        demo_arr = self.demographic_information_array(study_completion)
        study_completion_arr = study_completion.downloadable_attributes_values

        custom_results_arr = []
        parsed_custom_results = study_completion.custom_results_parsed
        study_completion.study.custom_results_schema.each_with_index do |trial, index|
          trial.keys.each do |key|
            if parsed_custom_results[index] == nil
              custom_results_arr << ""
            else
              custom_results_arr << parsed_custom_results[index][key]
            end
          end
        end
        csv << [demo_arr, study_completion_arr, custom_results_arr].flatten
      end
    end
  end

  def generate_multi_study_download_ALL_csv(data)
    # we need to sort all the study ids that are downloaded because we need to skip columns in this download type
    sorted_study_ids_arr = self.sorted_study_ids
    cols_to_skip = [0]
    sorted_study_ids_arr.each do |study_id|
      study = Study.find(study_id)

      # cols_to_skip is an array of how many columns each individual study takes up
      cols_to_skip << STUDY_COMPLETION_HEADERS.length + study.custom_results_csv_headers.length
    end


    CSV.generate do |csv|
      csv << self.csv_headers
      @data.order(study_id: :asc).each do |study_completion|
        study_completion_arr = []
        demo_arr = self.demographic_information_array(study_completion)
        #byebug
        indexOfStudyId = sorted_study_ids_arr.index(study_completion.study_id)

        # [0, 10, 25][0..1].reduce(0, :+) -> 10 --> it sums up a range to figure out how many blank columns we need to add
        # Array.new(...) { "" } creates an n array with "" as each element
        study_completion_arr << Array.new(cols_to_skip[0..indexOfStudyId].reduce(0, :+)) { "" }
        study_completion_arr << study_completion.downloadable_attributes_values

        parsed_custom_results = study_completion.custom_results_parsed

        # a json schema is uploaded when custom results are needed -- this loops through the schema and adds the data to the csv
        study_completion.study.custom_results_schema.each_with_index do |trial, index|
          trial.keys.each do |key|
              # somtimes the users' results don't match the schema properly, this if statement handles that possibility
              if parsed_custom_results[index] == nil
                study_completion_arr << ""
              else
                study_completion_arr << parsed_custom_results[index][key]
              end
          end
        end
        # arrays in an array, flatten em to make one big ole array
        csv << [demo_arr, study_completion_arr].flatten
      end
    end
  end

  def generate_multi_study_download_mr_ft_csv(data)
    user_ids = @data.pluck(:user_id).uniq
    study_ids = @data.pluck(:study_id).uniq
    CSV.generate do |csv|
      csv << self.csv_headers
      user_ids.each do |user_id|
        # each user gets their own row
        study_completion_arr = []
        study_completions = @data.where(user_id: user_id).order(study_id: :asc)
        study_completions.each do |study_completion|
          @demo_arr = self.demographic_information_array(study_completion) # since we only reach this area when we download user data, I can make this assumption

          study_completion_arr << study_completion.downloadable_attributes_values


          parsed_custom_results = study_completion.custom_results_parsed
          study_completion.study.custom_results_schema.each_with_index do |trial, index|
            trial.keys.each do |key|
              if parsed_custom_results[index] == nil
                study_completion_arr << ""
              else
                study_completion_arr << parsed_custom_results[index][key]
              end
            end
          end
        end

        study_completion_data = study_completion_arr.flatten
        csv << [@demo_arr, study_completion_data].flatten
      end
    end
  end

  def is_single_study_download?
    return self.study_ids.length == 1
  end

  def sorted_study_ids
    study_ids = self.study_ids
    study_ids.map(&:to_i).sort
  end

  def to_csv
    @data = self.download_study_completions
    if is_single_study_download?
      puts "single study download"
      csv = self.generate_single_study_download_csv(@data)
      # each study completion gets their own row
    elsif self.download_type == "All" # multiple study download, all data
      # this means a user could have taken the study twice, so each study completion gets their own row, rather than each user getting their own row
      # due to the custom results of each study, it still needs to move all the study completion data to the right for the 2nd and beyond study
      csv = self.generate_multi_study_download_ALL_csv(@data)
    else # multiple studies download with first take or most recent
      csv = self.generate_multi_study_download_mr_ft_csv(@data)

    end
    return csv
  end
end
