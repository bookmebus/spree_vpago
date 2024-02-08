FactoryBot.define do
  factory :acleda_payment_method, class: Spree::Gateway::Acleda do
    name { "ACLEDA Bank Plc." }
    description { "Pay securely with ACLEDA Bank Plc." }
    active { true }

    preferred_acleda_type { "KHQR" }
    preferred_icon_name { "acleda" }

    preferred_payment_expiry_time_in_mn { 10 }
    preferred_host { "https://epaymentuat.acledabank.com.kh:8443" }
    preferred_login_id { "remoteuser" }
    preferred_password { "12345678" }
    preferred_merchant_id { "Fake-Ao01Lr/y10389Ww82q1Z7meWY=" }
    preferred_merchant_name { "BOOKMEBUS" }
    preferred_signature { "7c7504903" }
    preferred_deeplink_partner_id { "" }
    preferred_deeplink_data_encryption_key { "" }
    preferred_success_url { "https://example/webhook/acledas/success" }
    preferred_error_url { "https://example/webhook/acledas/error" }
    preferred_other_url { "https://example/webhook/acledas/return" }
    preferred_acleda_company_name { "BookMe+" }

    before(:create) do |payway_gateway|
      if payway_gateway.stores.empty?
        default_store = Spree::Store.default.persisted? ? Spree::Store.default : nil
        store = default_store || create(:store)

        payway_gateway.stores << store
      end
    end

    factory :acleda_khqr_payment_method do
      preferred_acleda_type { "KHQR" }
      preferred_acleda_payment_card { nil }
    end

    factory :acleda_xpay_mpgs_payment_method do
      preferred_acleda_type { "XPAY-MPGS" }

      trait :visa do
        preferred_acleda_payment_card { 0 }
      end

      trait :xpay do
        preferred_acleda_payment_card { 1 }
      end
    end
  end
end
