module Vpago
  module PayoutProfiles
    module Payway
      class PayoutProfileRequestUpdater < BasePayoutProfileRequest
        # override
        def request_path
          "api/merchant-portal/merchant-access/whitelist-account/update-whitelist-status"
        end

        def call
          json_response = request_to_payway
          return false if error_messages.any?

          code = json_response['status']['code']

          if code == '00'
            profile.verify!(json_response['data'])
          else
            profile.reset_verification!
            @error_messages << json_response['status']
          end

          error_messages.empty?
        end
      end
    end
  end
end
