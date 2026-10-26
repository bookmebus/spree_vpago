module Vpago
  module WingMiniApp
    # Builds the doPayment() payload (Wing Web JS Bridge SDK spec, Native API #2).
    #
    # useDefault is hardcoded true for this first cut — no "let the user pick
    # another account" UI yet, same scope cut as shipping login before payment.
    class Checkout
      def initialize(payment)
        @payment = payment
      end

      # Pure fields only — no payment_method preference lookup involved, safe to
      # render/log/test directly. appId is left out here: it needs the gateway's
      # own app_id, so it's added in #signed_payload alongside additionalKey instead.
      def payload
        {
          account: account,
          amount: amount,
          currency: currency,
          useDefault: true
        }
      end

      # The full payload doPayment() actually needs, with appId and the
      # server-side-only additionalKey.hash merged in. Never render
      # `secret_api_key` itself into the page — only this derived hash.
      def signed_payload
        payload.merge(appId: app_id, additionalKey: { hash: hash, remark: '' })
      end

      def account
        @payment.number
      end

      def amount
        format('%.2f', @payment.amount)
      end

      def currency
        @payment.currency
      end

      private

      def app_id
        payment_method.app_id
      end

      # uppercase(account+amount+currency+secretApiKey), per the spec.
      def hash
        plaintext = "#{account}#{amount}#{currency}#{payment_method.secret_api_key}"
        Digest::SHA256.hexdigest(plaintext.upcase).upcase
      end

      def payment_method
        @payment.payment_method
      end
    end
  end
end
