module Api
  module Common
    module SuccessResponse
      extend ActiveSupport::Concern

      included do
        def success_response(message:, collection: nil, options: {})
          if collection.nil?
            { statusCode: Api::Common::Errorable::ERROR_CODE[:success], successMessage: message }.merge(options)
          else
            { statusCode: Api::Common::Errorable::ERROR_CODE[:success], successMessage: message }
              .merge(data: collection.serializable_hash)
              .merge(options)
          end
        end
      end
    end
  end
end
