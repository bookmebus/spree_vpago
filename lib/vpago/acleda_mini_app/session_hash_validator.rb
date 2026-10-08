module Vpago
  module AcledaMiniApp
    # Verifies the HMAC-SHA256 signature ACLEDA sends via the X-Acleda-Signature
    # header on the Session Initialization request (POST /mini_app/acleda), before
    # we look up or create the user. Mirrors AcledaMobile::CallbackValidator's
    # keyed-HMAC pattern, but out-of-band in a header instead of the JSON body.
    class SessionHashValidator
      def initialize(options)
        @options = options
      end

      def call
        valid?
      end

      # The key ACLEDA signs with lives only on their Spree::OauthApplication
      # (MiniAppProvider::AcledaBank#secret_key), so it can be rotated from the admin
      def secret_key
        @options[:secret_key].presence
      end

      def valid?
        return false if secret_key.blank? || @options[:hash].blank?

        ActiveSupport::SecurityUtils.secure_compare(computed_hash, @options[:hash].to_s)
      end

      def computed_hash
        message = "#{@options[:phone]}#{@options[:first_name]}#{@options[:last_name]}"

        OpenSSL::HMAC.hexdigest(OpenSSL::Digest.new('sha256'), secret_key, message)
      end
    end
  end
end
