FactoryBot.define do
  factory :wing_sdk_payment, class: Spree::Payment do
    amount { 29.99 }
    association(:payment_method, factory: :wing_sdk_gateway)
    association(:source, factory: :wing_sdk_payment_source)
    order
    state { 'checkout' }
  end
end
