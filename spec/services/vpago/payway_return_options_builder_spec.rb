require 'spec_helper'

RSpec.describe Vpago::PaywayReturnOptionsBuilder do
  context 'json' do
    let(:params) {
      {
        :tran_id => "PAYKFU1N",
        :apv => "355207", 
        :status => 0,
        :return_params => "{\"tran_id\":\"PAYKFU1N\"}",
        :controller => "spree/webhook/payways",
        :action => "v2_return",
        :payway => {"tran_id"=>"PAYKFU1N", "apv"=>"355207", "status"=>0, "return_params"=>"{\"tran_id\":\"PAYKFU1N\"}"}
      }
    }

    subject { described_class.new(params: params) }

    before do
      allow(subject).to receive(:merchant_profile_content_type).and_return('json')
    end

    describe '#tran_id' do
      it 'return correct tran_id base on params' do
        expect(subject.tran_id).to eq 'PAYKFU1N'
      end
    end

    describe '#payment' do
      it 'return correct payment base on tran_id' do
        payment = create(:payment, number: 'PAYKFU1N')

        expect(subject.tran_id).to eq 'PAYKFU1N'
        expect(subject.payment).to eq payment
      end
    end
  end
end
