require 'faraday'

module Vpago
  module PayoutProfiles
    module Payway
      class BasePayoutProfileRequest
        attr_reader :profile, :base_url, :error_messages

        # to be override
        def request_path; end

        def initialize(profile)
          @base_url = profile.preferred_base_url
          @profile = profile
          @error_messages = []
        end

        def connection
          Faraday::Connection.new(url: base_url)
        end

        def request_to_payway
          response = connection.post(request_path) do |request|
            request.headers['language'] = 'en'
            request.headers['Content-Type'] = 'application/json'
            request.body = PayoutProfileRequestParamsBuilder.new(Date.current, profile).request_params.to_json
          end

          json_response = JSON.parse(response.body)

          @error_messages << response.body if json_response.nil? || json_response['status'].nil?

          json_response
        end
      end
    end
  end
end
