class Spree::VpagoPaymentSource <  Spree::Base
  belongs_to :payment_method
  belongs_to :user, class_name: 'Spree::User'
  belongs_to :updated_by_user, class_name: 'Spree::User'
  has_one :payment, as: :source

  # validates :updated_reason, presence: true, on: :update

end