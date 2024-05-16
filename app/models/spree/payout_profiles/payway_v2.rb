module Spree
  module PayoutProfiles
    class PaywayV2 < Spree::PayoutProfile
      preference :base_url, :string
      preference :payee, :string
      preference :merchant_id, :string
      preference :api_key, :string
      preference :rsa_public_key, :text

      before_validation -> { self.preferred_payee = bank_account_number }

      # override
      def registered_in_bank?
        response_data['payee'].present?
      end

      # override
      def allow_to_verify_with_bank?
        preferred_base_url.present? &&
          preferred_payee.present? &&
          preferred_merchant_id.present? &&
          preferred_api_key.present? &&
          preferred_rsa_public_key.present?
      end
    end
  end
end
