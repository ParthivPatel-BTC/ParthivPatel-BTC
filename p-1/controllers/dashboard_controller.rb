class DashboardController < ApplicationController
  before_action :validate_current_user

  #TODO: Refactoring
  def index
    cookies[:desired_study] = nil
    @completed_studies = current_user.study_completions.includes(study: [:rich_text_purpose_of_study, :rich_text_related_research, :rich_text_understading_the_results])

    @completed_studies_data = []
    @completed_studies.each do |result|
      study = result.study
      show_standard_results = !study.js_presentation_url.url
      graph_data = result.linear_gradient_graph_computation
      
      completed_study = {
          study_id: result.id,
          study_name: study.name,
          completed_on: date_as_mmddyy(result.completed_on),
          purpose_of_study: study.purpose_of_study.body.to_s,
          understading_the_results: study.understading_the_results.body.to_s,
          related_research: study.related_research.body.to_s,
          score_details: {
              study_id: result.id,
              score: result.score,
              score_as_percent_of_max: result.score_as_percent_of_max,
              average_score_as_percent_of_max: result.average_score_as_percent_of_max,
              rounded_average_score: result.rounded_average_score,
              show_standard_results: show_standard_results,
              graph_data: graph_data,
              left_density: graph_data[:left_density],
              right_density: graph_data[:right_density],
              max_score:  graph_data[:max_score]
          },
          show_standard_results: show_standard_results
      }
      unless show_standard_results
        completed_study[:assets] = {
            css_url: study.css_url,
            js_presentation_url: study.js_presentation_url
        }
      end

      @completed_studies_data << completed_study
    end
  end
end
