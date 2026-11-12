require 'spec_helper'
require 'google/cloud/firestore'

RSpec.describe Vpago::FirestoreClients do
  let(:default_account) { { project_id: 'default-project' } }
  let(:other_account) { { project_id: 'other-project' } }

  before do
    allow(Rails.application.credentials).to receive(:cloud_firestore_service_account).and_return(default_account)
    allow(Google::Cloud::Firestore).to receive(:new) { instance_double(Google::Cloud::Firestore::Client) }
  end

  describe '.fetch' do
    it 'defaults to the cloud_firestore_service_account project' do
      described_class.fetch

      expect(Google::Cloud::Firestore).to have_received(:new).with(project_id: 'default-project', credentials: default_account)
    end

    it 'reuses one client per project within a process' do
      expect(described_class.fetch(default_account)).to be(described_class.fetch)
    end

    it 'keeps a separate client for each Firebase project' do
      expect(described_class.fetch(other_account)).not_to be(described_class.fetch(default_account))
    end

    it 'builds a fresh client in a forked child instead of reusing the parent channel' do
      parent_client = described_class.fetch
      allow(Process).to receive(:pid).and_return(Process.pid + 1)

      expect(described_class.fetch).not_to be(parent_client)
    end
  end
end
