require 'spec_helper'

RSpec.describe Spree::Gateway::PaywayV2, type: :model do
  let!(:default_payout_profile) { create(:payway_payout_profile, active: true, bank_account_number: '333', default: true, verified_at: DateTime.current)}  
  let(:payment_method) { create(:payway_v2_gateway) }
  let(:payment) { create(:payment, payment_method: payment_method) }

  describe '#default_payout_profile' do
    it 'returns the default payout profile' do
      expect(payment_method.default_payout_profile).to eq(Spree::PayoutProfiles::PaywayV2.default)
    end
  end

  describe '#support_payout?' do
    it { expect(create(:payway_v2_gateway, preferred_payment_option: 'cards').support_payout?).to be false }
    it { expect(create(:payway_v2_gateway, preferred_payment_option: 'abapay_khqr').support_payout?).to be true }
    it { expect(create(:payway_v2_gateway, preferred_payment_option: 'abapay_khqr_deeplink').support_payout?).to be true }
  end

  describe '#support_pre_auth?' do
    it { expect(create(:payway_v2_gateway).support_pre_auth?).to be true }
  end

  describe '#enable_payout?' do
    context 'when default payout is receivable' do
      it 'returns true' do
        default_payout_profile.verify!({})

        expect(default_payout_profile.receivable?).to be true
        expect(payment_method.enable_payout?).to be true
      end
    end

    context 'when default payout is not receivable' do
      it 'returns false' do
        default_payout_profile.reset_verification!

        expect(default_payout_profile.receivable?).to be false
        expect(payment_method.enable_payout?).to be false
      end
    end
  end

  describe '#enable_pre_auth?' do
    it 'returns true when column :enable_pre_auth is true' do
      payment_method.update(enable_pre_auth: true)
      expect(payment_method.enable_pre_auth?).to be true
    end
  end

  describe '#auto_capture?' do
    context 'when pre-auth is enabled' do
      it 'returns false' do
        payment_method.update(enable_pre_auth: true)

        expect(payment_method.enable_pre_auth?).to be true
        expect(payment_method.auto_capture?).to be false
      end
    end

    context 'when pre-auth is disable' do
      it 'returns true' do
        payment_method.update(enable_pre_auth: false)

        expect(payment_method.enable_pre_auth?).to be false
        expect(payment_method.auto_capture?).to be true
      end
    end
  end

  # this is called when pre-auth is enabled
  describe '#authorize' do
    context 'when transaction checker response paid' do
      let(:checker) { Vpago::PaywayV2::TransactionStatus.new(payment) }

      before do
        allow(checker).to receive(:success?).and_return(true)
        allow(checker).to receive(:json_response).and_return({ 'status'=>'any-result' })
        allow(payment_method).to receive(:check_transaction).and_return(checker)
      end

      it 'check transaction with bank & save response to db & return success' do
        response = payment_method.authorize(nil, nil, payment.gateway_options)

        expect(payment.reload.transaction_response).to eq({ 'status'=>'any-result' })
        expect(response.success?).to be true
      end
    end

    context 'when transaction checker response unpaid' do
      let(:checker) { Vpago::PaywayV2::TransactionStatus.new(payment) }

      before do
        allow(checker).to receive(:success?).and_return(false)
        allow(checker).to receive(:json_response).and_return({ 'status'=>'any-result' })
        allow(payment_method).to receive(:check_transaction).and_return(checker)
      end

      it 'check transaction with bank & save response to db & return fail' do
        response = payment_method.authorize(nil, nil, payment.gateway_options)

        expect(payment.reload.transaction_response).to eq({ 'status'=>'any-result' })
        expect(response.success?).to be false
      end
    end

    context 'when transaction checker raise Faraday errors' do
      let(:checker) { Vpago::PaywayV2::TransactionStatus.new(payment) }

      it 'rethrow the error' do
        allow(Vpago::PaywayV2::TransactionStatus).to receive(:new).and_return(checker)
        allow(checker).to receive(:check_remote_status).and_raise(Faraday::ConnectionFailed.new)
        expect { payment_method.authorize(nil, nil, payment.gateway_options) }.to raise_error(Faraday::ConnectionFailed)

        allow(checker).to receive(:check_remote_status).and_raise(Faraday::TimeoutError.new)
        expect { payment_method.authorize(nil, nil, payment.gateway_options) }.to raise_error(Faraday::TimeoutError)

        allow(checker).to receive(:check_remote_status).and_raise(StandardError.new)
        expect { payment_method.authorize(nil, nil, payment.gateway_options) }.to raise_error(StandardError)
      end
    end
  end

  # this is called when pre-auth is disabled, it captures amount from bank immediately.
  describe '#purchase' do
    let(:checker) { Vpago::PaywayV2::TransactionStatus.new(payment) }

    context 'when transaction checker response paid with payout' do
      before do
        allow(checker).to receive(:success?).and_return(true)
        allow(checker).to receive(:json_response).and_return({ 'status'=>'any-result', "payout"=>[{"acc"=>"002092768", "amt"=>"54.00", "acc_name"=>"*********ount", "whitelist_id"=>"85"}] })
        allow(payment_method).to receive(:check_transaction).and_return(checker)
      end

      it 'check transaction with bank & save response to db, confirm payout & return success' do
        expect(payment_method).to receive(:confirm_payouts).and_return([true, {}])

        response = payment_method.purchase(nil, nil, payment.gateway_options)

        expect(payment.reload.transaction_response).to eq({ 'status'=>'any-result', "payout"=>[{"acc"=>"002092768", "amt"=>"54.00", "acc_name"=>"*********ount", "whitelist_id"=>"85"}] })
        expect(response.success?).to be true
      end
    end

    context 'when transaction checker response paid without payout' do
      before do
        allow(checker).to receive(:success?).and_return(true)
        allow(checker).to receive(:json_response).and_return({ 'status'=>'any-result' })
        allow(payment_method).to receive(:check_transaction).and_return(checker)
      end

      it 'check transaction with bank & save response to db, skip confirming payout & return success' do
        expect(payment_method).not_to receive(:confirm_payouts)

        response = payment_method.purchase(nil, nil, payment.gateway_options)

        expect(payment.reload.transaction_response).to eq({ 'status'=>'any-result' })
        expect(response.success?).to be true
      end
    end

    context 'when transaction checker response unpaid' do
      let(:checker) { Vpago::PaywayV2::TransactionStatus.new(payment) }

      before do
        allow(checker).to receive(:success?).and_return(false)
        allow(checker).to receive(:json_response).and_return({ 'status'=>'any-result' })
        allow(payment_method).to receive(:check_transaction).and_return(checker)
      end

      it 'check transaction with bank & save response to db & return fail' do
        response = payment_method.authorize(nil, nil, payment.gateway_options)

        expect(payment.reload.transaction_response).to eq({ 'status'=>'any-result' })
        expect(response.success?).to be false
      end
    end

    context 'when transaction checker raise Faraday errors' do
      let(:checker) { Vpago::PaywayV2::TransactionStatus.new(payment) }

      it 'rethrow the error' do
        allow(Vpago::PaywayV2::TransactionStatus).to receive(:new).and_return(checker)
        allow(checker).to receive(:check_remote_status).and_raise(Faraday::ConnectionFailed.new)
        expect { payment_method.purchase(nil, nil, payment.gateway_options) }.to raise_error(Faraday::ConnectionFailed)

        allow(checker).to receive(:check_remote_status).and_raise(Faraday::TimeoutError.new)
        expect { payment_method.purchase(nil, nil, payment.gateway_options) }.to raise_error(Faraday::TimeoutError)

        allow(checker).to receive(:check_remote_status).and_raise(StandardError.new)
        expect { payment_method.purchase(nil, nil, payment.gateway_options) }.to raise_error(StandardError)
      end
    end
  end

  describe '#capture' do
    context 'when both pre-auth & payout is enabled' do
      before do
        expect(payment_method).to receive(:enable_pre_auth?).and_return(true)
      end

      context 'when confirmed pre-auth success' do
        it 'confirm pre-auth, payout & return success' do
          expect(payment_method).to receive(:complete_pre_auth).and_return([true, {}])

          expect(payment_method).to receive(:payout_total_from_response).and_return(10)
          expect(payment_method).to receive(:confirm_payouts).and_return([true, {}])
  
          response = payment_method.capture(nil, nil, payment.gateway_options)
          expect(response.success?).to be true
        end
      end

      context 'when confirmed pre-auth failed' do
        it 'did not confirm payout & return failded' do
          expect(payment_method).to receive(:complete_pre_auth).and_return([false, {}])

          expect(payment_method).not_to receive(:payout_total_from_response)
          expect(payment_method).not_to receive(:confirm_payouts)
  
          response = payment_method.capture(nil, nil, payment.gateway_options)
          expect(response.success?).to be false
        end
      end
    end

    context 'when pre-auth is enabled but payout is disabled' do
      before do
        expect(payment_method).to receive(:enable_pre_auth?).and_return(true)
        expect(payment_method).to receive(:payout_total_from_response).and_return(nil)
      end

      it 'only confirm pre-auth & return success' do
        expect(payment_method).to receive(:complete_pre_auth).and_return([true, {}])
        expect(payment_method).not_to receive(:confirm_payouts)

        response = payment_method.capture(nil, nil, payment.gateway_options)
        expect(response.success?).to be true
      end
    end

    context 'when pre-auth is disabled but payout is enabled' do
      it 'only confirm payout & return success' do
        expect(payment_method).to receive(:enable_pre_auth?).and_return(false)
        expect(payment_method).to receive(:payout_total_from_response).and_return(10)

        expect(payment_method).not_to receive(:complete_pre_auth)
        expect(payment_method).to receive(:confirm_payouts).and_return([true, {}])

        response = payment_method.capture(nil, nil, payment.gateway_options)
        expect(response.success?).to be true
      end
    end
  end

  describe '#void' do
    context 'when pre-auth is enabled' do
      context 'when pre-auth canceler response success' do
        it 'send request to cancel the pre-auth with bank & return success' do
          expect(payment_method).to receive(:enable_pre_auth?).and_return(true)
          expect(payment_method).to receive(:cancel_pre_auth).and_return([true, { 'status'=>'any-result' }])

          response = payment_method.void(nil, payment.gateway_options)
          expect(response.success?).to be true
        end
      end

      context 'when pre-auth canceler response fail' do
        it 'send request to cancel the pre-auth with bank & return fail' do
          expect(payment_method).to receive(:enable_pre_auth?).and_return(true)
          expect(payment_method).to receive(:cancel_pre_auth).and_return([false, { 'status'=>'any-result' }])

          response = payment_method.void(nil, payment.gateway_options)
          expect(response.success?).to be false
        end
      end
    end

    context 'when pre-auth is disable' do
      it 'return success true directly' do
        expect(payment_method).to receive(:enable_pre_auth?).and_return(false)
        expect(payment_method).not_to receive(:cancel_pre_auth)

        response = payment_method.void(nil, payment.gateway_options)
        expect(response.success?).to be true
      end
    end
  end

  describe '#check_transaction' do
    let(:checker) { Vpago::PaywayV2::TransactionStatus.new(payment) }

    context 'when payout is enabled' do
      it 'initialize TransactionStatus and call .call' do
        allow(payment_method).to receive(:enable_payout?).and_return(true)

        expect(Vpago::PaywayV2::TransactionStatus).to receive(:new).with(payment).and_return(checker)
        expect(checker).to receive(:call)

        payment_method.send(:check_transaction, payment)
      end
    end

    context 'when payout is disabled' do
      it 'initialize TransactionStatusV2 and call .call' do
        allow(payment_method).to receive(:enable_payout?).and_return(false)

        expect(Vpago::PaywayV2::TransactionStatusV2).to receive(:new).with(payment).and_return(checker)
        expect(checker).to receive(:call)

        payment_method.send(:check_transaction, payment)
      end
    end
  end

  describe '#cancel_pre_auth' do
    let(:canceler) { Vpago::PaywayV2::PreAuthCanceler.new(payment) }

    it 'execute .call and returns success with both request & response data' do
      expect(Vpago::PaywayV2::PreAuthCanceler).to receive(:new).with(payment).and_return(canceler)
      expect(canceler).to receive(:call)
      expect(canceler).to receive(:success?).and_return(true)
      expect(canceler).to receive(:request_data).and_return({ 'merchant_id' => 'any-merchant-id' })
      expect(canceler).to receive(:json_response).and_return({ 'status' => { 'code' => '00' } })

      success, data = payment_method.send(:cancel_pre_auth, payment)
      expect(success).to be true
      expect(data[:request]).to eq({ 'merchant_id' => 'any-merchant-id' })
      expect(data[:response]).to eq({ 'status' => { 'code' => '00' } })
    end

    context 'with VCR integration' do
      before do
        allow_any_instance_of(Vpago::PaywayV2::PreAuthCanceler).to receive(:cancel_url).and_return('https://checkout-sandbox.payway.com.kh/api/merchant-portal/merchant-access/online-transaction/pre-auth-cancellation')
        allow_any_instance_of(Vpago::PaywayV2::PreAuthCanceler).to receive(:merchant_auth_encryption).and_return('mocked_encrypted_value')
      end

      it 'returns both request and response data on success' do
        VCR.use_cassette('payway_v2_pre_auth_canceler_status_0') do
          success, data = payment_method.send(:cancel_pre_auth, payment)

          expect(success).to be true
          expect(data[:request]).to be_a(Hash)
          expect(data[:request]).to have_key(:merchant_id)
          expect(data[:response]).to be_a(Hash)
          expect(data[:response]['status']['code']).to eq('00')
          expect(data[:response]['transaction_status']).to eq('CANCELLED')
        end
      end

      it 'returns both request and response data on failure' do
        VCR.use_cassette('payway_v2_pre_auth_canceler_invalid_transaction') do
          success, data = payment_method.send(:cancel_pre_auth, payment)

          expect(success).to be false
          expect(data[:request]).to be_a(Hash)
          expect(data[:response]).to be_a(Hash)
          expect(data[:response]['status']['message']).to eq('Invalid Transaction')
        end
      end
    end
  end


  describe '#complete_pre_auth' do
    let(:completer) { Vpago::PaywayV2::PreAuthCompleter.new(payment) }

    it 'execute .call and returns success with both request & response data' do
      expect(Vpago::PaywayV2::PreAuthCompleter).to receive(:new).with(payment).and_return(completer)
      expect(completer).to receive(:call)
      expect(completer).to receive(:success?).and_return(true)
      expect(completer).to receive(:request_data).and_return({ 'merchant_id' => 'any-merchant-id' })
      expect(completer).to receive(:json_response).and_return({ 'status' => { 'code' => '00' }, 'transaction_status' => 'COMPLETED' })

      success, data = payment_method.send(:complete_pre_auth, payment)
      expect(success).to be true
      expect(data[:request]).to eq({ 'merchant_id' => 'any-merchant-id' })
      expect(data[:response]).to eq({ 'status' => { 'code' => '00' }, 'transaction_status' => 'COMPLETED' })
    end

    context 'with VCR integration' do
      before do
        allow_any_instance_of(Vpago::PaywayV2::PreAuthCompleter).to receive(:complete_url).and_return('https://checkout-sandbox.payway.com.kh/api/merchant-portal/merchant-access/online-transaction/pre-auth-completion')
        allow_any_instance_of(Vpago::PaywayV2::PreAuthCompleter).to receive(:merchant_auth_encryption).and_return('mocked_encrypted_value')
      end

      it 'returns both request and response data on success' do
        VCR.use_cassette('payway_v2_pre_auth_completer_status_0') do
          success, data = payment_method.send(:complete_pre_auth, payment)

          expect(success).to be true
          expect(data[:request]).to be_a(Hash)
          expect(data[:request]).to have_key(:merchant_id)
          expect(data[:response]).to be_a(Hash)
          expect(data[:response]['status']['code']).to eq('00')
          expect(data[:response]['transaction_status']).to eq('COMPLETED')
        end
      end

      it 'returns both request and response data on failure' do
        VCR.use_cassette('payway_v2_pre_auth_completer_invalid_transaction') do
          success, data = payment_method.send(:complete_pre_auth, payment)

          expect(success).to be false
          expect(data[:request]).to be_a(Hash)
          expect(data[:response]).to be_a(Hash)
          expect(data[:response]['status']['message']).to eq('Invalid Transaction')
        end
      end
    end
  end

  describe '#confirm_payouts' do
    context 'when payout in db 100% matched with payout total from response' do
      let!(:payout1) { create(:payout, payment: payment, amount: 5.0, state: :created) }
      let!(:payout2) { create(:payout, payment: payment, amount: 4.0, state: :created) }
      let!(:payout3) { create(:payout, payment: payment, amount: 3.0, state: :created) }

      before do 
        payment.transaction_response  = { "payout": [ { "amt": "5.00" }, { "amt": "7.00" } ]}
        payment.save!
      end

      it 'set confirmed to db and return success' do        
        expect(payout1.confirmed?).to be false
        expect(payout2.confirmed?).to be false
        expect(payout3.confirmed?).to be false

        success, params = payment_method.send(:confirm_payouts, payment)

        expect(success).to be true
        expect(params).to eq({:payout_total => 12.0, :expect_payout_total => 12.0})

        expect(payout1.reload.confirmed?).to be true
        expect(payout2.reload.confirmed?).to be true
        expect(payout3.reload.confirmed?).to be true

        expect(payment_method.send(:payout_total_from_response, payment)).to be 12.0
      end
    end
  end

  describe '#payout_total_from_response' do
    context 'when payment.transaction_response[:payout] is nil' do
      it 'return nil' do
        payment.transaction_response = nil
        payment.save!
        expect(payment_method.send(:payout_total_from_response, payment.reload)).to be nil

        payment.transaction_response = { "status": 0, 'description': 'any-response-here' }
        payment.save!
        expect(payment_method.send(:payout_total_from_response, payment.reload)).to be nil
      end
    end

    context 'when payment.transaction_response[:payout] is present' do
      it 'return total payout base on transaction_response' do
        payment.transaction_response = 	{ "payout": [{"acc": "002092768", "amt": "54.00", "acc_name": "*********ount", "whitelist_id": "85"} ]}
        payment.save!
        expect(payment_method.send(:payout_total_from_response, payment.reload)).to be 54.00
      end
    end
  end
end
