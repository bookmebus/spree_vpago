FactoryBot.define do
  factory :cash_on_payment_method, class: Spree::PaymentMethod::CashOn do
    name { 'Cash On Delivery' }
    description { 'Pay with cash.' }
    active { true }

    before(:create) do |payment_method|
      if payment_method.stores.empty?
        default_store = Spree::Store.default.persisted? ? Spree::Store.default : nil
        store = default_store || create(:store)

        payment_method.stores << store
      end
    end
  end
end
