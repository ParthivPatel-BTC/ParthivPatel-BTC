module Api
  module Common
    module Errorable
      extend ActiveSupport::Concern

      ERROR_CODE = {
        unauthorized: 401,
        bad_request: 400,
        not_found: 404,
        forbidden: 403,
        validation: 100,
        unprocessable_entity: 422,
        success: 200
      }

      included do
        def error_response(error_hash)
          {
            status: ERROR_CODE[error_hash[:status_code]],
            code: ERROR_CODE[error_hash[:error_code]],
            title: error_hash[:title],
            message: error_hash[:message]
          }
        end

        def render_error(message:, title: '', error_code:, status_code:, options: {})
          render json: {
            error: error_response(
              status_code: status_code,
              error_code: error_code,
              title: title,
              message: message
            )
        }.merge(options), status: error_code
        end
      end
    end
  end
end
