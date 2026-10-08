FactoryBot.define do
  factory :vattanac_payment, class: Spree::Payment do
    amount { 19.99 }
    association(:payment_method, factory: :vattanac_gateway)
    association(:source, factory: :payway_payment_source)
    order
    state { 'checkout' }
    number { "#{SecureRandom.hex(3).upcase}" }
  end
end
