module Vpago
  module WingMiniApp
    module Session
      # Wing Mini App session init (getProfile). Same gates as ACLEDA, but the trust comes
      # from a profile Wing signed and handed to the browser, not from a server-to-server
      # call — so there is no key to name the caller with, only the signature to check.
      class Create
        prepend Spree::ServiceModule::Base

        def call(profile:, gate:)
          @gate = gate

          return failure({ status: :unauthorized }, 'missing or unknown api key') unless gate.api_key_accepted?
          return failure({ status: :forbidden }, 'address not allowed') unless gate.address_allowed?

          verification = SpreeCmCommissioner::WingMiniApp::ProfileVerifier.call(profile: profile)
          return failure(nil, verification.error) unless verification.success?

          # After the signature, never before: a trip here is correctly signed traffic flooding us.
          return failure({ status: :too_many_requests }, 'too many requests') if throttled?(profile)

          user_result = SpreeCmCommissioner::WingMiniApp::FindOrCreateUser.call(profile: profile, gate: gate)
          return failure(user_result.value, user_result.error) unless user_result.success?

          success(mini_app_url: mini_app_url(user_result.value[:user]))
        end

        private

        attr_reader :gate

        def throttled?(profile)
          gate.session_exceeded?(phone: intel_phone(profile[:phone] || profile['phone']))
        end

        def intel_phone(phone)
          return nil if phone.blank?

          SpreeCmCommissioner::PhoneNumberParser.call(phone_number: phone).intel_phone_number
        end

        def mini_app_url(user)
          # A JWT signed with the user's secure_token. Passed as `wing_session_key`
          # so the OAuth grant routes it to the Wing authenticator.
          session_key = SpreeCmCommissioner::UserSessionJwtToken.encode(
            { user_id: user.id },
            user.reload.secure_token
          )

          "#{Spree::Store.default.formatted_url}/mini_app/wing?wing_session_key=#{session_key}"
        end
      end
    end
  end
end
