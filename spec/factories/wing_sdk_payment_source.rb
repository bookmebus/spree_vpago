FactoryBot.define do
  factory :wing_sdk_payment_source, class: Spree::VpagoPaymentSource do
    payment_option { 'wing_sdk' }
    payment_status { '' }
  end
end
