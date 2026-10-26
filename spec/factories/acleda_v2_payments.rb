FactoryBot.define do
  factory :acleda_v2_payment, class: Spree::Payment do
    amount { 29.99 }
    association(:payment_method, factory: :acleda_v2_gateway)
    association(:source, factory: :acleda_payment_source)
    order
    state { 'checkout' }
  end
end
