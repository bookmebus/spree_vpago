require 'faraday'

module Vpago
  module PaywayV2
    class TransactionStatus < Base
      attr_accessor :error_message
      attr_accessor :result

      def call
        prepare
        process
      end

      def prepare
        @error_message = nil
        @result = nil
      end

      def process
        @response = check_remote_status

        if @response.status == 200
          if json_response['status'] != 0 
            fail!(json_response['description'])
          else
            @result = json_response
          end
        else
          fail!( @response.body)
        end
      end

      def check_remote_status
        conn = Faraday::Connection.new do |faraday|
          faraday.request  :url_encoded
        end
    
        data = {
          req_time: req_time,
          merchant_id: merchant_id,
          tran_id: transaction_id,
          hash: checker_hmac
        }

       conn.post(check_transaction_url, data)
      end

      def json_response
        @json ||= JSON.parse(@response.body)
      end

      def fail!(message)
        @error_message = message
      end

      def success?
        @error_message == nil
      end

      def checker_hmac
        data = "#{req_time}#{merchant_id}#{transaction_id}"
        hash = Base64.encode64(OpenSSL::HMAC.digest(OpenSSL::Digest.new('sha512'), api_key, data))

        # somehow php counter part are not able to decode if the \n present.
        hash.delete("\n")
      end

      def check_transaction_url
        "#{host}#{ENV['PAYWAY_CHECK_TRANSACTION_PATH']}"
      end
    end
  end
end
