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
end
