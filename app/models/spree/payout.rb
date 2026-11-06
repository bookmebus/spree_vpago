module Spree
  class Payout < Base
    include Metadata

    belongs_to :payout_profile, class_name: 'Spree::PayoutProfile', required: true, inverse_of: :payouts
    belongs_to :payoutable, required: false, inverse_of: :payouts, polymorphic: true
    belongs_to :payment, class_name: 'Spree::Payment', required: true, inverse_of: :payouts

    enum state: { created: 0, confirmed: 1 }

    validates :payout_profile_id, uniqueness: { scope: %i[payoutable_type payoutable_id payment_id] }

    delegate :currency, to: :payment

    extend DisplayMoney
    money_methods :amount, :outstanding_amount,
                  :amount_owed_to_vendor

    def amount_owed_to_vendor
      private_metadata&.dig('amount_owed_to_vendor')&.to_f
    end
  end
end
