FactoryBot.define do
  factory :vattanac_gateway, class: Spree::Gateway::Vattanac do
    name { 'Vattanac Gateway' }

    preferred_generate_payment_url { 'https://example.com/vattanac/payments/generate' }
    preferred_access_token_url { 'https://example.com/vattanac/token' }
    preferred_check_transaction_url { 'https://example.com/vattanac/transactions/check' }

    preferred_username { 'test_user' }
    preferred_password { 'test_pass' }
    preferred_merchant_id { 'merchant_123' }
    preferred_payment_type { 'GOLF_TICKET' }

    before(:create) do |gateway|
      if gateway.stores.empty?
        default_store = Spree::Store.default.persisted? ? Spree::Store.default : nil
        store = default_store || create(:store)

        gateway.stores << store
      end
    end
  end
end
