module Vpago
  module PayoutProfiles
    module Payway
      class PayoutProfileRequestCreator < BasePayoutProfileRequest
        # override
        def request_path
          'api/merchant-portal/merchant-access/whitelist-account/add-whitelist-payout'
        end

        # code:
        # "00": Success!
        # "PTL148": Payee already exists.
        def call
          json_response = request_to_payway
          return false if @error_messages.any?

          code = json_response['status']['code']

          if code == '00'
            profile.verify!(json_response['data'])
          elsif code == 'PTL148'
            handle_existing_account(json_response)
          elsif code.present?
            profile.reset_verification!
            @error_messages << json_response['status']
          end

          error_messages.empty?
        end

        # if bank return that account already created,
        # but account is not yet exist in our database,
        # we can call updater to verify the profile as well as get account infos from bank.
        def handle_existing_account(json_response)
          other_existing_profile = Spree::PayoutProfile.where.not(id: profile.id).find_by(
            type: profile.type,
            bank_account_number: profile.bank_account_number
          )

          if other_existing_profile.nil?
            PayoutProfileRequestUpdater.new(profile).call
          else
            profile.reset_verification!
            @error_messages << json_response['status']
          end
        end
      end
    end
  end
end
