FactoryBot.define do
  factory :acleda_payment, class: Spree::Payment do
    amount { 29.99 }
    association(:payment_method, factory: :acleda_payment_method)
    association(:source, factory: :acleda_mobile_payment_source)
    order
    state { 'checkout' }
  end
end
