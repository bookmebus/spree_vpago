FactoryBot.define do
  factory :cash_on_payment, class: Spree::Payment do
    amount { 29.99 }
    association(:payment_method, factory: :cash_on_payment_method)
    association(:source, factory: :acleda_payment_source)
    order
    state { 'checkout' }
  end
end
