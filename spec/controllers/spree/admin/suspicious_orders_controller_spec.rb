require 'spec_helper'

# Exercises the private filter directly, like the payments decorator spec,
# to avoid coupling to admin authentication infrastructure.
RSpec.describe Spree::Admin::SuspiciousOrdersController do
  let(:controller) { described_class.new }
  let!(:order) { create(:order) }
  let!(:request_booking) { create(:order) }

  describe '#exclude_request_bookings' do
    context 'when spree_orders has no request_state column' do
      it 'returns every order' do
        result = controller.send(:exclude_request_bookings, Spree::Order.all)

        expect(result).to contain_exactly(order, request_booking)
      end
    end

    # request_state comes from spree_cm_commissioner, so the dummy app only
    # has it while this example runs; the DDL rolls back with the transaction.
    context 'when spree_orders has a request_state column' do
      before do
        ActiveRecord::Base.connection.add_column(:spree_orders, :request_state, :string)
        Spree::Order.reset_column_information
        Spree::Order.where(id: request_booking.id).update_all(request_state: 'requested')
      end

      after { Spree::Order.reset_column_information }

      it 'excludes request bookings' do
        result = controller.send(:exclude_request_bookings, Spree::Order.all)

        expect(result).to contain_exactly(order)
      end
    end
  end
end
