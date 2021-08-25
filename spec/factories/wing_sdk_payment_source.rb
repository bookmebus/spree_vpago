FactoryBot.define do
  factory :wing_sdk_payment_source, class: Spree::VpagoPaymentSource do
    transaction_id { 'FTR000111' }
    payment_option { 'wing_sdk' }
    payment_status { '' }
  end
end
