FactoryBot.define do
  # Credit card payment
  factory :payway_payment_source, class: Spree::VpagoPaymentSource do
    payment_option { 'cards' }
    payment_status { '' }
  end
end
