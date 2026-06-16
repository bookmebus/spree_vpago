require 'spec_helper'

RSpec.describe VpagoLogger do
  describe '.log' do
    let(:label) { 'test_event' }
    let(:data) { { key: 'value' } }

    before { allow(Rails.logger).to receive(:info) }

    it 'logs message without block' do
      expect(Rails.logger).to receive(:info).once
      VpagoLogger.log(label: label, data: data)
    end

    it 'logs initial and final message with block' do
      expect(Rails.logger).to receive(:info).twice
      result = VpagoLogger.log(label: label, data: data) { :result }
      expect(result).to eq(:result)
    end
  end

  describe '.safe_serialize' do
    it 'serializes primitives to strings' do
      expect(VpagoLogger.safe_serialize(nil)).to eq('')
      expect(VpagoLogger.safe_serialize(true)).to eq('true')
      expect(VpagoLogger.safe_serialize(123)).to eq('123')
      expect(VpagoLogger.safe_serialize('test')).to eq('test')
      expect(VpagoLogger.safe_serialize(:symbol)).to eq('symbol')
    end

    it 'serializes hashes recursively' do
      hash = { key: 'value', nested: { inner: 123 } }
      result = VpagoLogger.safe_serialize(hash)
      expect(result['key']).to eq('value')
      expect(result['nested']['inner']).to eq('123')
    end

    it 'serializes arrays recursively' do
      array = [1, 'two', { three: 3 }]
      result = VpagoLogger.safe_serialize(array)
      expect(result).to eq(['1', 'two', { 'three' => '3' }])
    end

    it 'serializes dates and times to ISO8601' do
      date = Date.new(2024, 1, 15)
      time = Time.new(2024, 1, 15, 12, 30, 45, '+00:00')
      expect(VpagoLogger.safe_serialize(date)).to eq('2024-01-15')
      expect(VpagoLogger.safe_serialize(time)).to match(/2024-01-15T12:30:45/)
    end

    it 'serializes ActiveJob with class, id, and arguments' do
      job = double('ActiveJob::Base')
      allow(job).to receive(:is_a?).and_return(false)
      allow(job).to receive(:is_a?).with(ActiveJob::Base).and_return(true)
      allow(job).to receive(:class).and_return(double(name: 'TestJob'))
      allow(job).to receive(:job_id).and_return('abc-123')
      allow(job).to receive(:arguments).and_return([1, 'test'])

      result = VpagoLogger.safe_serialize(job)
      expect(result[:job_class]).to eq('TestJob')
      expect(result[:job_id]).to eq('abc-123')
      expect(result[:arguments]).to eq(['1', 'test'])
    end

    it 'serializes objects with id to class and id' do
      obj = double('Model', id: 999, class: double(name: 'User'))
      allow(obj).to receive(:respond_to?).with(:id).and_return(true)
      expect(VpagoLogger.safe_serialize(obj)).to eq({ class: 'User', id: 999 })
    end

    it 'serializes objects without id to string' do
      obj = double('Object', to_s: 'custom_string')
      allow(obj).to receive(:respond_to?).with(:id).and_return(false)
      expect(VpagoLogger.safe_serialize(obj)).to eq('custom_string')
    end
  end

  describe '.error' do
    it 'logs error message' do
      allow(Rails.logger).to receive(:error)
      expect(Rails.logger).to receive(:error).once
      VpagoLogger.error(label: 'error_event', data: { error: 'failed' })
    end
  end
end
