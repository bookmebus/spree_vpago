FactoryBot.define do
  factory :true_money_gateway, class: Spree::Gateway::TrueMoney do
    name { 'True Money Gateway' }

    preferred_client_id { 'test_client_id' }
    preferred_client_secret { 'test_client_secret' }
    preferred_private_key { 'test_private_key' }
    preferred_check_transaction_url { 'https://example.com/merchant/transactions/ext-ref' }
    preferred_refund_url { 'https://example.com/merchants/payments/refunds' }
    preferred_generate_payment_url { 'https://example.com/retail-payment/view/v2/generate' }
    preferred_access_token_url { 'https://example.com/merchants/token' }
    preferred_android_package_name { 'com.centralmarket.app.dev' }

    before(:create) do |payway_gateway|
      if payway_gateway.stores.empty?
        default_store = Spree::Store.default.persisted? ? Spree::Store.default : nil
        store = default_store || create(:store)

        payway_gateway.stores << store
      end
    end
  end
end
