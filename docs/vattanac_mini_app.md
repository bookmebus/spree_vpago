## Vattanac Mini App Payment Configuration

To configure Vattanac Mini App payment, set the following preferences on the payment method:

1. Add the **Partner Code** (`preferred_partner_code`) – this value is sent in the HTTP request header as `Partner-Code`.  
2. Add the **Refund URL** (`preferred_refund_url`) – this URL is used to trigger refund API requests.

### Example:


- Partner Code: `your-partner-code`  
- Refund URL: `https://your-api.com/refund`
