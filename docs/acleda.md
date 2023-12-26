# ACLEDA

From latest document of ACLEDA and [documents](https://drive.google.com/drive/folders/1BusMWt6ul8QbDb1R-2HBz-Gduc0zJk1D), there are 2 types of payments:
- XPAY (xpay or card)
- KHQR

Both can be created via `Spree::Gateway::Acleda`. Following are instructions to create these payment methods in admin dashboard:

## Getting Start
To get start, request ACLEDA following:
- Request credentials (provide them email). They will send us following credentials via email:
  ```
  Merchant ID: AoGxxxxxxxxxxxEVY=
  Merchant name: BOOKMEBUS
  Remote User: remoteuser
  Remote password: Bxxxxxxxxxx3
  ```
  Also note that they are not usually provide the signature key. Signature is a required credential to create acleda session, so you need request them if they are't provided yet.

- Request account/app to test:
  - ACLEDA account, for test XPAY. eg. 00010221574410
  - Cards like VISA, master, for XPAY card (pay with card)
  - ACLEDA app & provide them your phone. For scan KHQR.

## Setup Payment Methods
To setup ACLEDA payment method:
- Go to admin dashboard /admin/payment_methods/
- Click on "New Payment Method" and fill details with following instructions & example:
  - Product Name in ACLEDA view. eg. BookMe+
  - Host: https://epaymentuat.acledabank.com.kh:8443
  - Signature: `"Signature" provided by ACLEDA`
  - Payment Expiry Time In Mn: 10
  - Merchant Name: `"Merchant name" provided by ACLEDA`
  - Password: `"Remote password" provided by ACLEDA`
  - Login: `"Remote User" provided by ACLEDA`
  - Merchant: `"Merchant ID" provided by ACLEDA`
  - Success Url: `whitelisted-url`/webhook/acledas/success 
    eg. https://example.com/webhook/acledas/success
  - Error Url: `whitelisted-url`/webhook/acledas/error
  - Other Url:`whitelisted-url`/webhook/acledas/return
  - Icon Name: acleda

Above are details for overall payment type of ACLEDA, to support it for specific type, insert following details:

### 1. for XPAY
- Payment Type: XPAY-MPGS
- Payment Card: 0 - XPAY

### 2. for XPAY (card)
- Payment Type: XPAY-MPGS
- Payment Card: 1 - Visa, Master Card, etc.

### 3. for KHQR
- Payment Type: KHQR
- Payment Card: (this field is ignored for KHQR, can put anything)

## Merchant Logo
- To update merchant logo inside ACLEDA view, override following path:
  [app/assets/images/vpago/payway/acleda_merchant_logo_300x300.png](../app/assets/images/vpago/payway/acleda_merchant_logo_300x300.png)

## Expected Outcome

| XPAY | XPAY (card) | KHQR |
| - | - | - |
| ![xpay](https://github.com/bookmebus/spree_vpago/assets/29684683/c8d7d022-7b1c-4d5c-91e9-d9fe53ea8cec) | ![xpay_card](https://github.com/bookmebus/spree_vpago/assets/29684683/48712fd7-8e3d-4116-b2f6-c3e2adbbe791) | ![khqr](https://github.com/bookmebus/spree_vpago/assets/29684683/5c1290aa-624c-4e36-a879-2e94961346fa) |
