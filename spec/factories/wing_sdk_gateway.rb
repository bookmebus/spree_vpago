FactoryBot.define do
  factory :wing_sdk_gateway, class: Spree::Gateway::WingSdk do
    name { 'WingPay Payment Gateway' }
  end
end
