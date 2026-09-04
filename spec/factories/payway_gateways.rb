FactoryBot.define do
  factory :payway_gateway, class: Spree::Gateway::Payway do
    name { 'Payway Payment Gateway' }

    before(:create) do |payway_gateway|
      if payway_gateway.stores.empty?
        default_store = Spree::Store.default.persisted? ? Spree::Store.default : nil
        store = default_store || create(:store)

        payway_gateway.stores << store
      end
    end
  end
end
