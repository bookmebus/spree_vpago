require 'spec_helper'

RSpec.describe Vpago::OrderProcessorJob, type: :job do
  let!(:order) { create(:order_with_line_items) }
  let!(:processor) { Vpago::OrderProcessor.new(order: order) }

  it 'is enqueued on the payment_processing queue' do
    expect {
      described_class.perform_later(order_number: order.number)
    }.to have_enqueued_job(described_class)
      .with(order_number: order.number)
      .on_queue('payment_processing')
  end

  describe '#perform' do
    it 'finds order & calls process order' do
      expect(Spree::Order).to receive(:find_by!).with({ number: order.number }).and_return(order)
      expect(Vpago::OrderProcessor).to receive(:new).with(order: order).and_return(processor)
      expect(processor).to receive(:call)

      Vpago::OrderProcessorJob.perform_now({ order_number: order.number })
    end
  end
end
