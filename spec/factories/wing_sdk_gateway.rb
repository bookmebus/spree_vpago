FactoryBot.define do
  factory :wing_sdk_gateway, class: Spree::Gateway::WingSdk do
    name { 'WingPay Payment Gateway' }

    before(:create) do |payway_gateway|
      if payway_gateway.stores.empty?
        default_store = Spree::Store.default.persisted? ? Spree::Store.default : nil
        store = default_store || create(:store)

        payway_gateway.stores << store
      end
    end
  end
end
