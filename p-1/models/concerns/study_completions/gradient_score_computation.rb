# frozen_string_literal: true

module StudyCompletions::GradientScoreComputation
  extend ActiveSupport::Concern
  MAX_COLOR = { r: 89.0, g: 139.0, b: 147.0 }.freeze # Highest density
  MIN_COLOR = { r: 230.0, g: 233.0, b: 236.0 }.freeze # Lowest density

  def graph_data_mobile
    @graph_data_mobile ||= linear_gradient_graph_computation
  end

  def linear_gradient_graph_computation
    # Scores in study completions
    scores = StudyCompletion.get_scores_array(study.id)
    max_score = study.max_score.to_f

    # Current study completion score position
    score_pos = score.to_f * 100 / max_score
    
    #Work out the average score / mean
    average_score = study.average_score

     # Position of average score
    average_pos = average_score * 100 / max_score
    
    #calculate Standard deviation
    standard_deviation = calculate_standard_deviation(scores: scores, study: study, max_score: max_score, average_score: average_score)

    # calculate normal standard distribution
    left_density = average_score - 2 * standard_deviation
    right_density = average_score + 2 * standard_deviation
    
    {
      score: score,
      score_pos: score_pos,
      average_score: average_score,
      average_pos: average_pos,
      max_score: max_score,
      left_density: left_density,
      right_density: right_density
    }
  rescue Exception => e
    Rollbar.error(e, 'LinearGradient graph issue')
    {}
  end

  private

  def calculate_standard_deviation(scores:, study:, max_score:, average_score:)
    # Average score / Mean
    # Step 1. Work out the average score / mean
    # Position of average score
    average_pos = average_score * 100 / max_score

    # Step 2. Then for each number: subtract the Mean and square the result
    squared_difference = []
    scores.each do |score|
      squared_difference << (score - average_score) * (score - average_score)
    end
   
    # Step 3. Then work out the mean of those squared differences.
    number_of_scores = scores.count
    sum_of_squared_difference = squared_difference.inject(0){|sum,x| sum + x }
    mean_of_scored_diff = sum_of_squared_difference / number_of_scores

    # Step 4. Take the square root of the above result:
    return Math.sqrt(mean_of_scored_diff)
  end
end
