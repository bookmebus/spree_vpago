FactoryBot.define do
  factory :payway_v2_gateway, class: Spree::Gateway::PaywayV2 do
    name { 'Payway Payment Gateway' }
    preferred_merchant_id { 'contigoasia' }
    preferred_api_key { 'ec****40-****-****-****-fd1d****324b' }

    before(:create) do |payway_gateway|
      if payway_gateway.stores.empty?
        default_store = Spree::Store.default.persisted? ? Spree::Store.default : nil
        store = default_store || create(:store)

        payway_gateway.stores << store
      end
    end
  end
end
