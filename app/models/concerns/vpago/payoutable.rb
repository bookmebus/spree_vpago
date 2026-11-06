module Vpago
  module Payoutable
    extend ActiveSupport::Concern

    included do
      has_many :payouts, class_name: 'Spree::Payout', as: :payoutable
      has_many :confirmed_payouts_for_vendor, -> { confirmed.where(default: false) },
               class_name: 'Spree::Payout', as: :payoutable
    end
  end
end
