require 'spec_helper'

RSpec.describe Vpago::Payway::PaymentRequestUpdater, type: :model do
  let(:gateway) { create(:payway_gateway, auto_capture: true) }
  let(:payment_source) { create(:payway_payment_source, payment_method: gateway) }

  let(:order) { OrderWalkthrough.up_to( :payment) }
  let(:payment) { create(:payway_payment, payment_method: gateway, source: payment_source, order: order) }
  let(:user) { create(:user) }

  let(:status_updater) {
    payment.process!
    options = {
      updated_by_user_id: user.id,
      updated_reason: Spree.t('vpago.payments.checker_updated_by_description')
    }
    Vpago::Payway::PaymentRequestUpdater.new(payment, options)
  }


  describe 'success?' do
    it 'return true if error_message is not nil?' do
      expect(status_updater.success?).to eq true
    end

    it 'return false f error_message source is not nil' do
      status_updater.error_message = 'invalid transaction'
      expect(status_updater.success?).to eq false
    end
  end

  describe '#call' do
    context 'if check payway status is success' do
      it 'set error_message to nil and invoke payment status marker' do

        checker = double(:payway_status_checker, 'success?': true)
        allow(status_updater).to receive(:check_payway_status).and_return(checker)

        marker = double(:marker)
        options = {
          updated_by_user_id: user.id,
          updated_reason: Spree.t('vpago.payments.checker_updated_by_description'),
          status: true, 
          description: nil
        }
        expect(::Vpago::Payway::PaymentStatusMarker).to receive(:new).with(payment, options).and_return(marker)
        expect(marker).to receive(:call)

        status_updater.call

        expect(status_updater.error_message).to eq nil
        
      end
    end

    context 'if check payway status is success' do
      it 'set error_message to nil and invoke payment status marker' do

        error_message = "err" * 100
        description = error_message[0...255]

        checker = double(:payway_status_checker, 'success?': false, error_message: error_message )
        allow(status_updater).to receive(:check_payway_status).and_return(checker)

        options = {
          updated_by_user_id: user.id,
          updated_reason: Spree.t('vpago.payments.checker_updated_by_description'),
          status: false, 
          description: description
        }
        marker = double(:marker)
        expect(::Vpago::Payway::PaymentStatusMarker).to receive(:new).with(payment, options).and_return(marker)
        expect(marker).to receive(:call)

        status_updater.call
        expect(status_updater.error_message).to eq description
        
      end
    end
  end

end
