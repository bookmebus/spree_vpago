FactoryBot.define do
  factory :payway_gateway, class: Spree::Gateway::Payway do
    name { 'Payway Payment Gateway' }
  end
end
