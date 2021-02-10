FactoryBot.define do
  factory :payway_payment, class: Spree::Payment do
    amount { 29.99 }
    association(:payment_method, factory: :payway_gateway)
    association(:source, factory: :payway_payment_source)
    order
    state { 'checkout' }
  end
end
