require 'spec_helper'

RSpec.describe VpagoLogger do
  let(:test_event) { 'vpago.test.event' }
  let(:test_data) { { payment_number: 'P123', order_number: 'O456' } }

  describe '.log' do
    it 'logs info message with event and data' do
      expect(Rails.logger).to receive(:info) do |json|
        expect(JSON.parse(json)).to eq(
          'event' => test_event,
          'payment_number' => 'P123',
          'order_number' => 'O456'
        )
      end

      expect(VpagoLogger.log(event: test_event, data: test_data)).to eq(
        event: test_event,
        payment_number: 'P123',
        order_number: 'O456'
      )
    end

    it 'logs info message with only event when no data provided' do
      expect(Rails.logger).to receive(:info) do |json|
        expect(JSON.parse(json)).to eq('event' => test_event)
      end

      expect(VpagoLogger.log(event: test_event)).to eq(event: test_event)
    end

    it 'logs info message with nil data when data is nil' do
      expect(Rails.logger).to receive(:info) do |json|
        expect(JSON.parse(json)).to eq('event' => test_event)
      end

      expect(VpagoLogger.log(event: test_event, data: nil)).to eq(event: test_event)
    end
  end

  describe '.error' do
    it 'logs error message with event and data' do
      expect(Rails.logger).to receive(:error) do |json|
        expect(JSON.parse(json)).to eq(
          'event' => test_event,
          'payment_number' => 'P123',
          'order_number' => 'O456'
        )
      end

      expect(VpagoLogger.error(event: test_event, data: test_data)).to eq(
        event: test_event,
        payment_number: 'P123',
        order_number: 'O456'
      )
    end

    it 'logs error message with only event when no data provided' do
      expect(Rails.logger).to receive(:error) do |json|
        expect(JSON.parse(json)).to eq('event' => test_event)
      end

      expect(VpagoLogger.error(event: test_event)).to eq(event: test_event)
    end

    it 'logs error message with nil data when data is nil' do
      expect(Rails.logger).to receive(:error) do |json|
        expect(JSON.parse(json)).to eq('event' => test_event)
      end

      expect(VpagoLogger.error(event: test_event, data: nil)).to eq(event: test_event)
    end
  end

  describe 'integration test' do
    it 'produces valid JSON output' do
      expect {
        VpagoLogger.log(event: 'vpago.payment.test', data: { key: 'value' })
      }.not_to raise_error
    end
  end
end
