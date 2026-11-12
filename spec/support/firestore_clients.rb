RSpec.configure do |config|
  # FirestoreClients caches one client per project per process; specs stub
  # Google::Cloud::Firestore.new per example, so the cache must not carry one example's double into
  # the next.
  config.before { Vpago::FirestoreClients.reset! }
end
