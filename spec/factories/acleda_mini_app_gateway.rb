FactoryBot.define do
  factory :acleda_mini_app_gateway, class: Spree::Gateway::AcledaMiniApp do
    name { 'ACLEDA Mini App' }
    description { 'Pay securely with ACLEDA inside the ACLEDA mobile app.' }
    active { true }
    display_on { 'mini_app' }

    preferred_merchant_name { 'BOOKMEPLUS' }
    preferred_xpay_service_base_url { 'https://epaymentuat.acledabank.com.kh/BOOKMEPLUS/XPAYConnectorServiceInterfaceImplV2/XPAYConnectorServiceInterfaceImplV2RS' }
    preferred_payment_page_url { 'https://epaymentuat.acledabank.com.kh/BOOKMEPLUS/paymentPage.jsp' }
    preferred_merchant_id { 'Fake-Ao01Lr/y10389Ww82q1Z7meWY=' }
    preferred_login_id { 'remoteuser' }
    preferred_password { '12345678' }
    preferred_secret { 'secret' }
    preferred_payment_expiry_time_in_mn { 5 }

    before(:create) do |gateway|
      if gateway.stores.empty?
        default_store = Spree::Store.default.persisted? ? Spree::Store.default : nil
        store = default_store || create(:store)

        gateway.stores << store
      end
    end
  end
end
