require 'faraday'

module Vpago
  module WingSdk
    class TransactionStatusChecker < Base
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
          if json_response['errorCode'] != 200
            fail!(json_response['errorText'])
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
          username: username,
          rest_api_key: rest_api_key,
          remark: payment_number,
          sandbox: sandbox
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

      def check_transaction_url
        "#{host}/wingonlinesdk/inquiry"
      end
    end
  end
end
