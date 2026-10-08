FactoryBot.define do
  factory :wing_mini_app_gateway, class: Spree::Gateway::WingMiniApp do
    name { 'Wing Mini App Gateway' }
    display_on { 'mini_app' }

    before(:create) do |gateway|
      if gateway.stores.empty?
        default_store = Spree::Store.default.persisted? ? Spree::Store.default : nil
        store = default_store || create(:store)

        gateway.stores << store
      end
    end
  end
end
