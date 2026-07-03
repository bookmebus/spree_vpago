require 'spec_helper'

RSpec.describe Vpago::AcledaV2::Base do
  let(:order) { create(:order) }
  let(:payment) { create(:acleda_v2_payment, order: order) }

  subject(:base) { described_class.new(payment) }

  describe '#expiry_time' do
    context 'when the order has a hold with time remaining' do
      before { allow(order).to receive(:hold_expires_at).and_return(3.minutes.from_now + 10.seconds) }

      it 'returns the ceiled minutes left as a string' do
        expect(base.expiry_time).to eq('4')
      end
    end

    context 'when the order hold has already lapsed' do
      before { allow(order).to receive(:hold_expires_at).and_return(2.minutes.ago) }

      it 'falls back to the admin-configured preference' do
        expect(base.expiry_time).to eq('5')
      end
    end

    context 'when the order has a hold_expires_at of nil (no active hold)' do
      before { allow(order).to receive(:hold_expires_at).and_return(nil) }

      it 'falls back to the admin-configured preference' do
        expect(base.expiry_time).to eq('5')
      end
    end
  end
end
