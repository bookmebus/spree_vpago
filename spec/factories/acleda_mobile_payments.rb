FactoryBot.define do
  factory :acleda_mobile_payment, class: Spree::Payment do
    amount { 29.99 }
    association(:payment_method, factory: :acleda_mobile_gateway)
    association(:source, factory: :acleda_mobile_payment_source)
    order
    state { 'checkout' }
  end
end
