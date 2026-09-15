require 'spec_helper'

RSpec.describe Spree::V2::Storefront::CartSerializer do
  let(:order) { create(:order_with_line_items, state: :payment) }

  it 'exposes processing_url from the order' do
    allow(order).to receive(:processing_url).and_return('https://example.com/vpago_orders/processing')

    attributes = described_class.new(order).serializable_hash[:data][:attributes]

    expect(attributes[:processing_url]).to eq 'https://example.com/vpago_orders/processing'
  end
end
