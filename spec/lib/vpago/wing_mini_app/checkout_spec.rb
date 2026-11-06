require 'spec_helper'

RSpec.describe Vpago::WingMiniApp::Checkout do
  let(:order) { create(:order, currency: 'USD') }
  let(:payment) { create(:wing_mini_app_payment, number: 'PJ0MYD2Y', amount: 19.9, order: order) }
  let(:instance) { described_class.new(payment) }

  describe '#payload' do
    it 'returns the account/amount/currency doPayment expects' do
      result = instance.payload

      expect(result[:account]).to eq('PJ0MYD2Y')
      expect(result[:amount]).to eq('19.90')
      expect(result[:currency]).to eq('USD')
      expect(result[:useDefault]).to be true
    end
  end
end
