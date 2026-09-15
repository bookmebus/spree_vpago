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

      def secret_key
        ENV.fetch('ACLEDA_MINI_APP_SECRET_HASH_KEY', nil)
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
