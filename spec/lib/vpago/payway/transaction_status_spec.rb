require 'spec_helper'

RSpec.describe Vpago::Payway::TransactionStatus do
  describe "#gateway_params" do
    let(:payway_gateway) { 
      payway_gateway = create(:payway_gateway, auto_capture: true)
      payway_gateway.set_preference(:host, "https://payway-staging.ababank.com")
      payway_gateway.set_preference(:endpoint, "/api/pwvtenhv/")
      payway_gateway.set_preference(:api_key, "api_key")
      payway_gateway.set_preference(:merchant_id, "vtenh")
      payway_gateway.set_preference(:return_url, "https://vtenh.com/webkook/payway_return_url")
      payway_gateway.set_preference(:continue_success_url, "https://vtenh.com/webkook/payway_continue_url")
      payway_gateway.set_preference(:payment_option, "cards")
      payway_gateway.set_preference(:transaction_fee_fix, 0)
      payway_gateway.save
      payway_gateway
    }
    let(:payment_source) { create(:payway_payment_source, payment_method: payway_gateway) }

    let(:order) { OrderWalkthrough.up_to(:payment) }
    let(:payment) { create(:payway_payment, payment_method: payway_gateway, source: payment_source, order: order) }

    describe '#process' do
      describe "server response with status 200" do
        it "returns success if response payload has status = 0" do
          response = double(:transaction_check, status: 200, body: {status: 0}.to_json)
      
          transaction_status = Vpago::Payway::TransactionStatus.new(payment)
          allow(transaction_status).to receive(:check_remote_status).and_return(response)

          transaction_status.process

          expect(transaction_status.result).to match({"status"=>0})
          expect(transaction_status.success?).to eq true
        end

        it "returns failed if response payload has status != 0" do
          response = double(:transaction_check, status: 200, body: {status: 1, description: 'any-error-message'}.to_json)

          transaction_status = Vpago::Payway::TransactionStatus.new(payment)
          allow(transaction_status).to receive(:check_remote_status).and_return(response)

          transaction_status.process

          expect(transaction_status.result).to eq nil
          expect(transaction_status.success?).to eq false
          expect(transaction_status.error_message).to eq 'any-error-message'
        end
      end

      describe "server response status is not 200" do
        it "returns failed with error_message to response body" do
          response = double(:transaction_check, status: 400, body: 'any-body-response-message')

          transaction_status = Vpago::Payway::TransactionStatus.new(payment)
          allow(transaction_status).to receive(:check_remote_status).and_return(response)

          transaction_status.process

          expect(transaction_status.result).to eq nil
          expect(transaction_status.success?).to eq false
          expect(transaction_status.error_message).to eq 'any-body-response-message'
        end
      end
    end

    describe "#checker_hmac" do
      it "returns base64 hmac without newline char \\n" do
        transaction_id = "83716hf"
        transaction_status = Vpago::Payway::TransactionStatus.new(payment)
        allow(transaction_status).to receive(:transaction_id).and_return(transaction_id)
        result = transaction_status.checker_hmac
  
        expect(result).to eq 'kJ/VrXjWrLpN1L51Gi6ijOd2HR+75KHDdZWZxZfaz6VuY6qN8HH+4pq1NWvxT7DfiSXjSVkule8fRqg8nQaKPA=='
      end
    end

    describe '#check_transaction_url' do
      it "returns correct url if endpoint is terminated with /" do
        transaction_status = Vpago::Payway::TransactionStatus.new(payment)
        allow(transaction_status).to receive(:endpoint).and_return "/api/pwvtenhv/"
        result = transaction_status.check_transaction_url
        expect(result).to eq "https://payway-staging.ababank.com/api/pwvtenhv/check/transaction/"
      end

      it "add / and return correct url if endpoint is not terminated with /" do
        transaction_status = Vpago::Payway::TransactionStatus.new(payment)
        allow(transaction_status).to receive(:endpoint).and_return "/api/pwvtenhv"
        result = transaction_status.check_transaction_url
        expect(result).to eq "https://payway-staging.ababank.com/api/pwvtenhv/check/transaction/"
      end

    end
    
  end
end
