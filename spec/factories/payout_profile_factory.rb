FactoryBot.define do
  factory :payout_profile, class: Spree::PayoutProfile do
    name { FFaker::Name.name }
    bank_account_number { '002094060' }

    trait :random do
      sequence(:bank_account_number) { |n| "00209406#{n}" }
    end

    factory :payway_payout_profile, class: Spree::PayoutProfiles::PaywayV2 do
      preferred_base_url { 'https://checkout-sandbox.payway.com.kh' }
      preferred_merchant_id { 'contigoasia' }
      preferred_api_key { 'fffake-3api-4key-aipa-fd1d8key324b' }

      # invalid public key
      preferred_rsa_public_key { 
"-----BEGIN PUBLIC KEY-----
MIGfMA0GCSqGSIb3DQEBAQUAA4GNADCBiQKBgQCx1dw7dsoqmhq7Q1XWHTRQ2c67
cXhqSvGCijj3tEw1Qqqnyy/CI8gjE05gBNEp3bEB/lUEPaVEkjTdEbEp2safFQzJ
+DANRYYLT/f3cqWE/Qbn1jn/4odcK0lJbwA3AXTeW6BbDACHKun421gVaPuFI+zd
idh478qjYsklP2JzhQIDAQAB
-----END PUBLIC KEY-----"
      }
    end
  end
end
