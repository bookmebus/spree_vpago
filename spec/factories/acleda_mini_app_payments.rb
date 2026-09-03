FactoryBot.define do
  factory :acleda_mini_app_payment, class: Spree::Payment do
    amount { 29.99 }
    association(:payment_method, factory: :acleda_mini_app_gateway)
    association(:source, factory: :acleda_payment_source)
    order
    state { 'checkout' }
  end
end
