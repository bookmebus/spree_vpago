require 'spec_helper'

RSpec.describe Vpago::UserInformers::Firebase do
  describe '#document_reference_path' do
    let(:firestore_reference) { double(:firestore_reference, path: 'projects/central-market-internal/databases/(default)/documents/statuses/cart/2025-02-26/R851105933') }

    subject { described_class.new(nil) }

    it 'only return actual document path' do
      allow(subject).to receive(:firestore_reference).and_return(firestore_reference)
      expect(subject.document_reference_path).to eq("/statuses/cart/2025-02-26/R851105933")
    end
  end

  describe '#notify' do
    let(:order) { create(:order_with_line_items, state: :payment, payment_state: 'paid') }
    let(:now) { Time.current }
    let(:processing) { true }

    let(:firestore_reference) { double(:firestore_reference) }
    let(:histories_ref) { double(:histories_ref) }
    let(:history_doc_ref) { double(:history_doc_ref) }

    let(:data) do
      {
        processing: processing,
        message_code: :my_message_code,
        reason_code: :unable_to_connect_to_gateway,
        reason_message: 'This is reaason why error',
        order_state: order.state,
        payment_state: order.payment_state,
        updated_at: now
      }
    end

    subject { described_class.new(order) }

    before do
      allow(Time).to receive(:current).and_return(now)
    end

    it 'reload order, set document with newly input data & add it history' do
      # reload order
      expect(order).to receive(:reload).and_call_original

      # set data to document with merge: true
      expect(subject).to receive(:firestore_reference).and_return(firestore_reference).twice
      expect(firestore_reference).to receive(:set).with(data, merge: true)

      # add data to histories collection with 'my_message_code' as ID
      expect(firestore_reference).to receive(:col).with('histories').and_return(histories_ref)
      expect(histories_ref).to receive(:doc).with(:my_message_code).and_return(history_doc_ref)
      expect(history_doc_ref).to receive(:set).with(data)

      subject.notify(:my_message_code, processing, :unable_to_connect_to_gateway, 'This is reaason why error')
    end
  end
end
