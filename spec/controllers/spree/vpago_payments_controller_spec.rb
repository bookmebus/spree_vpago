require 'spec_helper'

RSpec.describe Spree::VpagoPaymentsController, type: :request do
  let(:order) { create(:order, number: 'R131576461') }
  let(:payment) { create(:payway_v2_payment, number: 'PJ0MYD2Y', order: order) }
  let(:checkout) { Vpago::PaywayV2::Checkout.new(payment) }

  describe 'POST #process_payment' do
    context 'when request from ABA (return)' do
      let(:params) { { tran_id: payment.number, return_params: checkout.return_params } }

      it 'find payment with return params & enqueues the PaymentProcessorJob' do
        expect {
          post '/vpago_payments/process_payment', params: params
        }.to have_enqueued_job(Vpago::PaymentProcessorJob).with(
          hash_including(payment_number: payment.number, enqueued_at: a_kind_of(Float))
        )
      end
    end
  end
end
