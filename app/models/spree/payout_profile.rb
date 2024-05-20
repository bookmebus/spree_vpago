module Spree
  class PayoutProfile < Base
    acts_as_paranoid

    has_many :payout_profile_products, class_name: 'Spree::PayoutProfileProduct', inverse_of: :payout_profile
    has_many :products, class_name: "Spree::Product", through: :payout_profile_products

    belongs_to :vendor, class_name: 'Spree::Vendor', optional: true, inverse_of: :payout_profiles

    validates :type, presence: true
    validates :name, presence: true
    validates :bank_account_number, presence: true, uniqueness: { scope: [:type, :vendor_id] }

    scope :payway, -> { where(type: 'Spree::PayoutProfiles::PaywayV2') }
    scope :verified, -> { where.not(verified_at: nil) }
    scope :active, -> { where(active: true) }

    before_save :ensure_default_exists_and_clear_vendor
    before_destroy :confirm_destroyable

    def self.default
      Rails.cache.fetch("default_payout_account/#{self.name.underscore}") do
        find_by(type: self.name, default: true)
      end
    end

    def verified?
      verified_at.present?
    end

    def registered_in_bank?
      true
    end

    def allow_to_verify_with_bank?
      true
    end

    def verify!(response_data)
      update_columns(
        verified_at: DateTime.current,
        response_data: response_data
      )
    end

    def reset_verification!
      update_columns(
        verified_at: nil
      )
    end

    def can_be_deleted?
      self.class.where.not(id: id, type: type).any?
    end

    private

    def ensure_default_exists_and_clear_vendor
      if default?
        self.class.where.not(id: id, type: type).update_all(default: false)
        self.vendor_id = nil
      elsif self.class.where(default: true, type: type).count.zero?
        self.default = true
        self.vendor_id = nil
      end
    end

    def confirm_destroyable
      unless can_be_deleted?
        errors.add(:base, :cannot_destroy_only_payout_profile)
        throw(:abort)
      end
    end  
  end
end
