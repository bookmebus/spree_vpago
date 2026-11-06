require 'faraday'

module Vpago
  module AcledaV2
    class Checkout < Base
      attr_reader :error_message

      def call
        @error_message = nil
        @response = open_session

        if @response.status != 500 && @response.status != 200
          @error_message = 'Server Error'
        elsif @response.status == 500 # mostly when passing a wrong parameter name
          @error_message = @response.body
        elsif json_response.dig('result', 'code') != 0 # invalid payload, wrong loginId, etc.
          @error_message = json_response.dig('result', 'errorDetails') || 'Unknown Error'
        end

        update_payment_source

        self
      end

      def failed?
        @error_message.present?
      end

      def json_response
        @json_response ||= parse_json(@response.body)
      end

      # KHQR/Card secure web redirect form fields (auto-POSTed to paymentPage.jsp).
      def gateway_params
        return {} if failed?

        {
          merchantID: merchant_id,
          sessionid: json_response.dig('result', 'sessionid'),
          paymenttokenid: payment_token_id,
          description: Base::PURCHASE_DESC,
          expirytime: expiry_time,
          amount: amount,
          quantity: '1',
          item: '1',
          invoiceid: order_number,
          currencytype: purchase_currency,
          transactionID: payment_number,
          successUrlToReturn: continue_success_url,
          errorUrl: continue_success_url
        }
      end

      # Deep Link redirect target.
      def deeplink_url
        return nil if failed?

        json_response.dig('result', 'deeplinkUrl')
      end

      private

      def open_session
        conn = Faraday::Connection.new

        conn.post(open_session_url) do |request|
          request.headers['Content-Type'] = Base::CONTENT_TYPE_JSON
          request.body = open_session_payload.to_json
        end
      end

      def open_session_payload
        base = {
          password: password,
          loginId: login_id,
          merchantID: merchant_id,
          hash: open_session_hash,
          xpayTransaction: xpay_transaction_base
        }

        if deeplink?
          base[:xpayTransaction].merge!(oprDevice: opr_device, callBackUrl: callback_url)
        else
          base[:xpayTransaction][:paymentCard] = payment_method.payment_card_value
        end

        base
      end

      def xpay_transaction_base
        {
          txid: payment_number,
          invoiceid: order_number,
          purchaseAmount: amount,
          purchaseCurrency: purchase_currency,
          purchaseDate: purchase_date,
          purchaseDesc: Base::PURCHASE_DESC,
          item: '1',
          quantity: '1',
          expiryTime: expiry_time
        }
      end

      def payment_token_id
        json_response.dig('result', 'xTran', 'paymentTokenid')
      end

      # Persist the paymentTokenid so check_transaction / the bank callback can
      # resolve the payment later. Wrap only the write in the writing role, since
      # the checkout form partial runs on a GET request (replica connection).
      def update_payment_source
        return if failed?

        ActiveRecord::Base.connected_to(role: :writing) do
          @payment.source.update_column(:transaction_id, payment_token_id)
        end
      end
    end
  end
end
