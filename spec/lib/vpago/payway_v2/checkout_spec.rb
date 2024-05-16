require 'spec_helper'

RSpec.describe Vpago::PaywayV2::Checkout do
  describe "#gateway_params" do
    let(:payment) { create(:payway_payment) }

    context 'view_type' do
      subject { described_class.new(payment) }

      before do
        allow(subject).to receive(:hash_hmac).and_return "fake_hash_hmac"
      end

      it 'add view_type to gateway_params if view_type is not nil' do
        allow(subject).to receive(:view_type).and_return "qr"

        expect(subject.gateway_params[:view_type]).to eq "qr"
        expect(subject.gateway_params).to have_key(:view_type)
      end

      it 'not add view_type to gateway_params if view_type is nil' do
        allow(subject).to receive(:view_type).and_return nil

        expect(subject.gateway_params).not_to have_key(:view_type)
      end
    end
  end
end
