require 'spec_helper'

RSpec.describe Vpago::VpagoPaymentsHelper, type: :helper do
  describe '#checkout_form_exists?' do
    it 'is true for a gateway payment method with a real form partial' do
      payment_method = create(:payway_v2_gateway)
      payment = build_stubbed(:payment, payment_method: payment_method)

      expect(helper.checkout_form_exists?(payment)).to be true
    end

    it 'is false for a payment method with no form partial (e.g. store credit, cash-on)' do
      order = create(:order)
      payment_method = create(:store_credit_payment_method, stores: [order.store])
      payment = build_stubbed(:payment, payment_method: payment_method)

      expect(helper.checkout_form_exists?(payment)).to be false
    end
  end

  describe '#checkout_form_partial_path' do
    it 'builds the path from the payment method class name' do
      payment_method = create(:payway_v2_gateway)
      payment = build_stubbed(:payment, payment_method: payment_method)

      expect(helper.checkout_form_partial_path(payment)).to eq('spree/vpago_payments/forms/spree/gateway/payway_v2')
    end
  end
end
