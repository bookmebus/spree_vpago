module Vpago
  module AcledaMiniApp
    module Session
      # Partner Session Initialization (ACLEDA Mini App Integration Spec, Step 01).
      #
      # ACLEDA POSTs { phone, first_name, last_name } with an X-Acleda-Signature HMAC
      # (see SessionHashValidator), checked before we touch the user so nobody can mint
      # a session for an arbitrary phone. We then find or create the customer, tag them
      # with the acleda_bank identity, and hand back a miniAppUrl carrying a session JWT.
      class Create
        prepend Spree::ServiceModule::Base

        # `signature`, not `hash`: an attr_reader named `hash` overrides Object#hash and
        # silently breaks this object as a Hash key.
        #
        # `gate` answers who is calling, from where and how often. The controller builds it:
        # the key header and the address exist only on the request.
        def call(gate:, phone: nil, first_name: nil, last_name: nil, signature: nil)
          return failure(nil, 'phone is required') if phone.blank?

          @phone = phone
          @first_name = first_name
          @last_name = last_name
          @signature = signature
          @gate = gate

          return failure({ status: :unauthorized }, 'missing or unknown api key') unless gate.api_key_accepted?
          return failure({ status: :forbidden }, 'address not allowed') unless gate.address_allowed?
          return failure(nil, 'invalid signature') unless valid_signature?
          return failure(nil, 'phone is invalid') if intel_phone.blank?
          return failure({ status: :too_many_requests }, 'too many requests') if gate.session_exceeded?(phone: intel_phone)

          user = find_or_create_user
          return failure(user, 'user creation failed') if user.nil? || !user.persisted?

          success(mini_app_url: mini_app_url(user))
        end

        private

        attr_reader :phone, :first_name, :last_name, :signature, :gate

        # Only asked where this call would mint an account — the damage a leaked key does.
        # Returning customers never spend that quota.
        def new_user_throttled?
          !acleda_identity.persisted? && find_existing_user.nil? && gate.new_user_exceeded?(phone: intel_phone)
        end

        def valid_signature?
          ::Vpago::AcledaMiniApp::SessionHashValidator.new(
            phone: phone, first_name: first_name, last_name: last_name, hash: signature,
            secret_key: gate.mini_app&.preferred_secret_key
          ).call
        end

        def find_or_create_user
          identity = acleda_identity

          # Returning customer: the ACLEDA identity already points at a user.
          return identity.user if identity.persisted?

          return nil if new_user_throttled?

          # New to ACLEDA: reuse a customer matched by phone, otherwise build one, then
          # tag them so the lookup above hits next time.
          user = find_existing_user || build_user
          identity.name = full_name
          user.user_identity_providers << identity
          user.save

          user
        end

        # Memoized: #new_user_throttled? asks the same questions, and this row is the one
        # that gets tagged onto the user.
        def acleda_identity
          @acleda_identity ||= SpreeCmCommissioner::UserIdentityProvider.acleda_bank.find_or_initialize_by(sub: phone)
        end

        def find_existing_user
          return @find_existing_user if defined?(@find_existing_user)
          return @find_existing_user = nil if intel_phone.blank?

          @find_existing_user = Spree::User.by_non_tenant.find_by(intel_phone_number: intel_phone)
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
          # A JWT signed with the user's secure_token. `session_key`, not `session_id`, so
          # the OAuth grant routes it to the ACLEDA authenticator.
          session_key = SpreeCmCommissioner::UserSessionJwtToken.encode(
            { user_id: user.id },
            user.reload.secure_token
          )

          "#{Spree::Store.default.formatted_url}/mini_app/acleda?session_key=#{session_key}"
        end

        def full_name
          [first_name, last_name].compact.join(' ').presence
        end

        def intel_phone
          return @intel_phone if defined?(@intel_phone)

          @intel_phone = SpreeCmCommissioner::PhoneNumberParser.call(phone_number: phone).intel_phone_number
        end
      end
    end
  end
end
