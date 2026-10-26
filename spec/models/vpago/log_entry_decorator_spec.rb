# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Vpago::LogEntryDecorator do
  describe '#parsed_details' do
    let(:response) do
      ActiveMerchant::Billing::Response.new(
        true,
        'Transaction successful',
        { transaction_id: '12345' },
        authorization: 'AUTH123'
      )
    end

    let(:details_hash) do
      {
        response: response,
        status: :success,
        metadata: { key: 'value' }
      }
    end

    let(:yaml_details) { YAML.dump(details_hash) }
    let(:log_entry) { Spree::LogEntry.new(details: yaml_details) }

    it 'parses YAML details with permitted classes' do
      parsed = log_entry.parsed_details

      expect(parsed).to be_a(Hash)
      expect(parsed[:response]).to be_a(ActiveMerchant::Billing::Response)
      expect(parsed[:response].message).to eq('Transaction successful')
      expect(parsed[:status]).to eq(:success)
      expect(parsed[:metadata]).to eq({ key: 'value' })
    end

    it 'handles ActiveMerchant::Billing::Response objects' do
      parsed = log_entry.parsed_details

      expect(parsed[:response].success?).to be true
      expect(parsed[:response].authorization).to eq('AUTH123')
      expect(parsed[:response].params).to eq({ 'transaction_id' => '12345' })
    end

    it 'handles Symbol objects' do
      parsed = log_entry.parsed_details

      expect(parsed[:status]).to be_a(Symbol)
      expect(parsed[:status]).to eq(:success)
    end

    it 'handles Hash objects' do
      parsed = log_entry.parsed_details

      expect(parsed[:metadata]).to be_a(Hash)
      expect(parsed[:metadata][:key]).to eq('value')
    end

    it 'memoizes the parsed result' do
      first_call = log_entry.parsed_details
      second_call = log_entry.parsed_details

      expect(first_call.object_id).to eq(second_call.object_id)
    end

    context 'with different Ruby versions' do
      it 'uses appropriate YAML.safe_load parameters' do
        expect(log_entry.parsed_details).to be_a(Hash)
      end
    end

    context 'when details contain only basic types' do
      let(:simple_details) { YAML.dump({ message: 'Test', count: 42 }) }
      let(:log_entry) { Spree::LogEntry.new(details: simple_details) }

      it 'parses simple YAML structures' do
        parsed = log_entry.parsed_details

        expect(parsed[:message]).to eq('Test')
        expect(parsed[:count]).to eq(42)
      end
    end
  end

  describe 'module inclusion' do
    it 'is prepended to Spree::LogEntry' do
      expect(Spree::LogEntry.ancestors).to include(Vpago::LogEntryDecorator)
    end

    it 'responds to parsed_details method' do
      log_entry = Spree::LogEntry.new

      expect(log_entry).to respond_to(:parsed_details)
    end
  end
end
