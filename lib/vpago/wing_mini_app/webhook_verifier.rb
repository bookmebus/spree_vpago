module Vpago
  module WingMiniApp
    # Verifies a Wing getStatus/webhook payload (Wing Web JS Bridge SDK spec,
    # Native-App Invoke #1 getStatus) is both authentic and correct for the
    # payment it claims to settle. Both checks live here, in one place:
    #
    # - the secretKey signature (proves Wing sent this, for this orderRef —
    #   unlike getProfile, appId is our own configured value here, not a payload
    #   field, since the spec's getStatus response never includes one)
    # - the doc-mandated amount/currency match (catches a validly-signed webhook
    #   that reports the wrong amount, since Wing holds the keys and could sign
    #   any amount for a real orderRef if something on their end got it wrong —
    #   not a forgery guard, since orderRef is itself part of what secretKey
    #   signs, so a valid signature is already bound to exactly this payment)
    class WebhookVerifier
      FIELDS = %w[orderRef debitAmount debitCcy transactionId transactionDate].freeze

      # payment is the specific one this settlement claims to be for — both what
      # verifies the signature (via its own payment_method's app_id/secret_api_key)
      # and what the amount/currency check runs against.
      def initialize(payload, payment)
        @payload = payload.with_indifferent_access
        @payment = payment
      end

      def valid?
        valid_signature? && amount_matches?
      end

      private

      attr_reader :payload, :payment

      def payment_method
        payment.payment_method
      end

      def valid_signature?
        received = payload['secretKey']
        received.present? && candidates.value?(received.to_s.upcase)
      end

      # Numeric comparison, not string: Wing's own spec says debitAmount is always
      # 2-decimal ("1.00"), but real payloads have sent "1" (no decimals) — same
      # kind of spec-vs-reality gap as getProfile's `sex` field.
      def amount_matches?
        payment.amount == BigDecimal(payload['debitAmount'].to_s) &&
          payment.currency.to_s.casecmp(payload['debitCcy'].to_s).zero?
      rescue ArgumentError, TypeError
        false
      end

      # Same spec-vs-reality gap, applied to the signature itself: Wing's own
      # secretKey may have been computed against the canonical 2-decimal
      # debitAmount even though what actually reached us isn't. Try both so a
      # formatting-only mismatch between what Wing hashed and what Wing sent
      # still verifies.
      def candidates
        {
          raw: hash_for(payload['debitAmount'].to_s),
          normalized: hash_for(normalized_debit_amount)
        }
      end

      def normalized_debit_amount
        format('%.2f', BigDecimal(payload['debitAmount'].to_s))
      rescue ArgumentError, TypeError
        payload['debitAmount'].to_s
      end

      def hash_for(debit_amount)
        fields = FIELDS.map { |field| field == 'debitAmount' ? debit_amount : payload[field].to_s }.join
        plaintext = "#{payment_method.app_id}#{fields}#{payment_method.secret_api_key}"
        Digest::SHA256.hexdigest(plaintext.upcase).upcase
      end
    end
  end
end
