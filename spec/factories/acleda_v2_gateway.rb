FactoryBot.define do
  factory :acleda_v2_gateway, class: Spree::Gateway::AcledaV2 do
    name { 'ACLEDA Bank Plc. V2' }
    description { 'Pay securely with ACLEDA Bank Plc.' }
    active { true }

    preferred_merchant_name { 'BOOKMEPLUS' }
    preferred_xpay_service_base_url { 'https://epaymentuat.acledabank.com.kh/BOOKMEPLUS/XPAYConnectorServiceInterfaceImplV2/XPAYConnectorServiceInterfaceImplV2RS' }
    preferred_payment_page_url { 'https://epaymentuat.acledabank.com.kh/BOOKMEPLUS/paymentPage.jsp' }
    preferred_merchant_id { 'Fake-Ao01Lr/y10389Ww82q1Z7meWY=' }
    preferred_login_id { 'remoteuser' }
    preferred_password { '12345678' }
    preferred_secret { 'secret' }
    preferred_payment_expiry_time_in_mn { 5 }
    preferred_acleda_v2_mode { 'khqr' }

    before(:create) do |gateway|
      if gateway.stores.empty?
        default_store = Spree::Store.default.persisted? ? Spree::Store.default : nil
        store = default_store || create(:store)

        gateway.stores << store
      end
    end
  end
end
