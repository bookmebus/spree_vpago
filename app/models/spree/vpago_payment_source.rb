class Spree::VpagoPaymentSource <  Spree::Base
  belongs_to :payment_method
  has_one :payment, as: :source
end
