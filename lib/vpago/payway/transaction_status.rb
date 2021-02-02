require 'faraday'

module Vpago
  module Payway
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

      def checker_hmac
        data = "#{merchant_id}#{transaction_id}"
        hash = Base64.encode64(OpenSSL::HMAC.digest(OpenSSL::Digest.new('sha512'), api_key, data))

        # somehow php counter part are not able to decode if the \n present.
        hash.delete("\n")
      end

      def process
        conn = Faraday::Connection.new do |faraday|
          faraday.request  :url_encoded
        end
    
        data = {
          tran_id: transaction_id,
          hash: checker_hmac
        }

        @response = conn.post(url, data)
    
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

      def json_response
        @json ||= JSON.parse(@response.body)
      end

      def fail!(message)
        @error_message = message
      end

      def success?
        @error_message == nil
      end

      def url
        endpoint + "check/transaction/"
      end

    end

  end
end
