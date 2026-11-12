require 'google/cloud/firestore'

module Vpago
  # Process-wide Cloud Firestore clients, one per Firebase project (`project_id`). Each new client
  # opens its own gRPC channel, TLS handshake and OAuth token fetch, which UserInformers::Firebase
  # used to pay on every order/payment status update.
  #
  # Clients are dropped when the PID changes so a forked worker (Puma preload_app!, Sidekiq, rake)
  # never reuses its parent's client. That only works while the parent made no Firestore RPC before
  # forking — gRPC refuses to run in a child after the parent used it — so never call Firestore
  # during app boot.
  module FirestoreClients
    MUTEX = Mutex.new

    class << self
      # service_account: [Hash] a Firebase service-account credential; defaults to
      # `cloud_firestore_service_account`.
      def fetch(service_account = default_service_account)
        project_id = service_account[:project_id]

        MUTEX.synchronize do
          reset_unlocked! if @pid != Process.pid
          @clients[project_id] ||= Google::Cloud::Firestore.new(project_id: project_id, credentials: service_account)
        end
      end

      def default_service_account
        Rails.application.credentials.cloud_firestore_service_account
      end

      # Specs stub Google::Cloud::Firestore.new per example; without this the first example's
      # double would be served to every later one.
      def reset!
        MUTEX.synchronize { reset_unlocked! }
      end

      private

      def reset_unlocked!
        @clients = {}
        @pid = Process.pid
      end
    end
  end
end
