# Documentation

[Preauthorization Integration with PayWay](https://www.payway.com.kh/developers/pre-authorization/)

## Getting Start

To start, request the following from ABA:

1. **Enable Pre-Authorization Service** to hold funds without immediate charge.
2. **RSA Public Key** use for merchant info encryption.

## Create Pre-Auth Transaction

Creating a pre-auth transaction is similar to creating a purchase transaction, the only difference is while you submit a purchase request you must include the parameter “type”value as “pre-auth” funds will be blocked on the customer’s debit/credit card or ABA Account once customer authenticate the transaction.


### Example Request

```json
{
  "req_time": "20210123234559",
  "merchant_id": "onlinesshop24",
  "tran_id": "00002894",
  "firstname": "Firstname",
  "lastname": "Lastname",
  "email": "email@textdomain.com",
  "phone": "0965965965",
  "amount": 5000,
  "type": "pre-auth",
  "payment_option": "abapay",
  "items": "W3snbmFtZSc6J3Rlc3QnLCdxdWFudGl0eSc6JzEnLCdwcmljZSc6JzEuMDAnfV0=",
  "currency": "KHR",
  "continue_success_url": "www.staticmerchanturl.com/Success",
  "return_deeplink": "",
  "custom_fields": "{\"Purcahse order ref\":\"Po-MX9901\", \"Customfield2\":\"value for custom field\"}",
  "return_param": "500 Character notes included here will be returned on pushback notification after transaction is successful.",
  "hash": "K3nd/2Z4g45Paoqx06QA3UQeHRC2Ts37zjudG7DqyyU2Cq0cvOFMYqwtEsXkaEmNOSiFh6Y+IHRdwnA2WA/M/Qg=="
}

```

## Complete Pre-Auth

After creating a pre-auth transaction, use the **Capture Pre-Auth** API to collect the blocked funds from the customer’s debit/credit card or ABA Account.

### API Endpoints:

- **Sandbox**:  
  [Checkout Sandbox - Pre-Auth Completion](https://checkout-sandbox.payway.com.kh/api/merchant-portal/merchant-access/online-transaction/pre-auth-completion)
- **Production**:  
  [Checkout Production - Pre-Auth Completion](https://checkout.payway.com.kh/api/merchant-portal/merchant-access/online-transaction/pre-auth-completion)

### Method: POST

### Example Request

```json
{
  "request_time": "20200728095315",
  "merchant_id": "ec000002",
  "merchant_auth": "b1453eac8cd686f90542c9d7dc026a3f70678afd",
  "hash": "w33R2bVPVKY9M4WmeGoQUUcmtrJYFofFuMrgTMBLj/g8kPfXgnpK//qpjptO+1D0nKbpFktqM"
}
```

### Create merchant_auth 
```json
{
  "mc_id": "ec000002",
  "tran_id": "00002894",
  "complete_amount": "0.01"
}
```
- Encrypt this json object using the public key

### Create Hash 

- Encrypt with sha512 (merchant_auth_encryption + request_time + merchant_id)

### Response:

**Success**:

```json
{
  "grand_total": "29.99",
  "currency": "USD",
  "transaction_status": "COMPLETED",
  "status": {
    "code": "00",
    "message": "Success!",
    "tran_id": "P1Y25BRA"
  }
}
```

## Cancel Pre-Auth

Use this API to release the blocked amount on the customer’s debit/credit card or ABA Account.

### API Endpoints:

- **Sandbox**:  
  [Checkout Sandbox - Pre-Auth Cancellation](https://checkout-sandbox.payway.com.kh/api/merchant-portal/merchant-access/online-transaction/pre-auth-cancellation)
- **Production**:  
  [Checkout Production - Pre-Auth Cancellation](https://checkout.payway.com.kh/api/merchant-portal/merchant-access/online-transaction/pre-auth-cancellation)

### Method: POST

### Example Request:

````json
{
    "request_time": "20200728095315",
    "merchant_id": "ec000002",
    "merchant_auth": "b1453eac8cd686f90542c9d7dc026a3f70678afd",
    "hash": "w33R2bVPVKY9M4WmeGoQUUcmtrJYFofFuMrgTMBLj/g8kPfXgnpK//qpjptO+1D0nKbpFktqM"
}
````

### Create merchant_auth 
```json
{
  "mc_id": "ec000002",
  "tran_id": "00002894",
}
```
- Encrypt this json object using the public key

### Create Hash 

- Encrypted with sha512 (merchant_id + merchant_auth_encryption + request_time)

### Response:

**Success**:

```json
{
  "grand_total": "30.00",
  "currency": "USD",
  "transaction_status": "CANCELLED",
  "status": {
    "code": "00",
    "message": "Success!",
    "tran_id": "PID657AX"
  }
}
````
