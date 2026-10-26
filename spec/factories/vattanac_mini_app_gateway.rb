FactoryBot.define do
  factory :vattanac_mini_app_gateway, class: Spree::Gateway::VattanacMiniApp do
    name { 'Vattanac Mini App Gateway' }

    before(:create) do |payway_gateway|
      if payway_gateway.stores.empty?
        default_store = Spree::Store.default.persisted? ? Spree::Store.default : nil
        store = default_store || create(:store)

        payway_gateway.stores << store
      end
    end
  end
end
