FactoryBot.define do

  factory :vattanac_mini_app_payment, class: Spree::Payment do
    amount { 29.99 }
    association(:payment_method, factory: :vattanac_mini_app_gateway)
    association(:source, factory: :payway_payment_source)
    order
    state { 'checkout' }
  end
end
