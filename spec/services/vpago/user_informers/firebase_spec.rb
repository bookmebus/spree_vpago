require 'spec_helper'

RSpec.describe Vpago::UserInformers::Firebase do
  describe '#firestore' do
    let(:service_account) { { project_id: 'default-project' } }

    before do
      allow(Rails.application.credentials).to receive(:cloud_firestore_service_account).and_return(service_account)
      allow(Google::Cloud::Firestore).to receive(:new) { instance_double(Google::Cloud::Firestore::Client) }
    end

    it 'shares one client across informers instead of building one per order' do
      expect(described_class.new(nil).firestore).to be(described_class.new(nil).firestore)
      expect(Google::Cloud::Firestore).to have_received(:new).once
    end
  end

  describe '#document_reference_path' do
    let(:firestore_reference) { double(:firestore_reference, path: 'projects/central-market-internal/databases/(default)/documents/statuses/cart/2025-02-26/R851105933') }

    subject { described_class.new(nil) }

    it 'only return actual document path' do
      allow(subject).to receive(:firestore_reference).and_return(firestore_reference)
      expect(subject.document_reference_path).to eq("/statuses/cart/2025-02-26/R851105933")
    end
  end

  describe '#notify_step' do
    let(:order) { create(:order_with_line_items) }
    let(:firestore_reference) { double(:firestore_reference) }
    let(:steps_ref) { double(:steps_ref) }
    let(:step_doc_ref) { double(:step_doc_ref) }
    let(:now) { Time.current }

    subject { described_class.new(order) }

    before { allow(Time).to receive(:current).and_return(now) }

    it "writes the step's own document, leaving the order's document alone" do
      allow(subject).to receive(:firestore_reference).and_return(firestore_reference)
      expect(firestore_reference).to receive(:col).with('steps').and_return(steps_ref)
      expect(steps_ref).to receive(:doc).with('seats_assigning').and_return(step_doc_ref)
      expect(step_doc_ref).to receive(:set).with({ status: :done, updated_at: now })
      expect(firestore_reference).not_to receive(:set)

      subject.notify_step(:seats_assigning, status: :done)
    end
  end

  describe '#notify expected_steps' do
    let(:order) { create(:order_with_line_items) }
    let(:firestore_reference) { double(:firestore_reference, set: nil) }

    subject { described_class.new(order) }

    before do
      allow(subject).to receive(:firestore_reference).and_return(firestore_reference)
      allow(firestore_reference).to receive(:col).and_return(double(doc: double(set: nil)))
      allow(order).to receive(:pending_completion_steps).and_return([:seats_assigning])
    end

    it 'tells the page which completion steps to wait for once the order is complete' do
      order.update_columns(state: 'complete', completed_at: Time.current)

      subject.order_is_completed(processing: false)

      expect(firestore_reference).to have_received(:set).with(hash_including(expected_steps: [:seats_assigning]), merge: true)
    end

    it 'leaves them out before completion' do
      subject.order_is_processing(processing: true)

      expect(firestore_reference).to have_received(:set).with(hash_excluding(:expected_steps), merge: true)
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
