FactoryBot.define do
  factory :acleda_mobile_gateway, class: Spree::Gateway::Payway do
    name { 'Acleda Mobile Gateway' }
  end
end
