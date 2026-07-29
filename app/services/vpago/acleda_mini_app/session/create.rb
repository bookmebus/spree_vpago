module Vpago
  module AcledaMiniApp
    module Session
      # Partner Session Initialization (ACLEDA Mini App Integration Spec, Step 01).
      #
      # ACLEDA calls POST /miniapp/acleda with { phone, first_name, last_name }.
      # We find or create the customer (tagged with the acleda_bank identity),
      # mint a session JWT, and return a session-based miniAppUrl for ACLEDA to
      # open in the WebView. The generic session_id OAuth grant validates the JWT
      # when the WebView later authenticates.
      class Create
        prepend Spree::ServiceModule::Base

        def call(phone: nil, first_name: nil, last_name: nil)
          return failure(nil, 'phone is required') if phone.blank?

          @phone = phone
          @first_name = first_name
          @last_name = last_name

          return failure(nil, 'phone is invalid') if intel_phone.blank?

          user = find_or_create_user
          return failure(user, 'user creation failed') if user.nil? || !user.persisted?

          success(mini_app_url: mini_app_url(user))
        end

        private

        attr_reader :phone, :first_name, :last_name

        def find_or_create_user
          identity = acleda_identity

          # Returning customer: the ACLEDA identity already points at a user.
          return identity.user if identity.persisted?

          # New to ACLEDA: reuse a customer matched by phone, otherwise build one,
          # then tag them with the acleda_bank identity so the lookup above hits
          # next time.
          user = find_existing_user || build_user
          identity.name = full_name
          user.user_identity_providers << identity
          user.save

          user
        end

        def acleda_identity
          SpreeCmCommissioner::UserIdentityProvider.acleda_bank.find_or_initialize_by(sub: phone)
        end

        def find_existing_user
          return if intel_phone.blank?

          Spree::User.by_non_tenant.find_by(intel_phone_number: intel_phone)
        end

        def build_user
          Spree::User.new(
            first_name: first_name,
            last_name: last_name,
            phone_number: phone,
            intel_phone_number: intel_phone,
            password: SecureRandom.base64(16),
            confirmed_at: Time.zone.now
          )
        end

        def mini_app_url(user)
          # A JWT signed with the user's secure_token. Passed as `session_key` (not
          # `session_id`) so the OAuth grant routes it to the ACLEDA authenticator,
          # which enforces the signature.
          session_key = SpreeCmCommissioner::UserSessionJwtToken.encode(
            { user_id: user.id },
            user.reload.secure_token
          )

          "#{Spree::Store.default.formatted_url}/mini_app/acleda?session_key=#{session_key}&ds=#{CGI.escape(disable_services)}"
        end

        def full_name
          [first_name, last_name].compact.join(' ').presence
        end

        def intel_phone
          return @intel_phone if defined?(@intel_phone)

          @intel_phone = SpreeCmCommissioner::PhoneNumberParser.call(phone_number: phone).intel_phone_number
        end

        # Services to disable in the mini app storefront. Configurable per ACLEDA's
        # requirement; defaults to none.
        def disable_services
          ENV.fetch('ACLEDA_MINI_APP_DISABLE_SERVICES', '')
        end
      end
    end
  end
end
