module Spree
  class Gateway::PaywayV2 < PaymentMethod
    preference :host, :string
    preference :api_key, :string
    preference :merchant_id, :string
    preference :payment_option, :string # 'abapay', 'cards', 'abapay_deeplink'
    preference :app_scheme, :text
    preference :transaction_fee_fix, :string
    preference :transaction_fee_percentage, :string
    preference :public_key, :text

    validates :preferred_public_key, presence: true, if: :enable_pre_auth?

    # override: partial to render in admin
    def method_type
      'payway_v2'
    end

    # override
    def default_payout_profile
      Spree::PayoutProfiles::PaywayV2.default
    end

    # override
    def payment_source_class
      Spree::VpagoPaymentSource
    end

    # override
    def support_payout?
      preferred_payment_option.in?(%w[abapay_khqr abapay_khqr_deeplink])
    end

    # override
    def support_pre_auth? = true

    # override
    def enable_payout?
      default_payout_profile.present? && default_payout_profile.receivable?
    end

    # override
    def enable_pre_auth?
      self[:enable_pre_auth]
    end

    # override
    # authorize payment if pre-auth is enabled, otherwise purchase / complete immediately.
    def auto_capture?
      !enable_pre_auth?
    end

    # override
    # authorize is used when pre auth enabled
    def authorize(_amount, _source, gateway_options = {})
      _, payment_number = gateway_options[:order_id].split('-')
      payment = Spree::Payment.find_by(number: payment_number)

      checker = check_transaction(payment)
      payment.update(transaction_response: checker.json_response)

      if checker.success?
        ActiveMerchant::Billing::Response.new(true, 'Payway Gateway: Authorized')
      else
        ActiveMerchant::Billing::Response.new(false, 'Payway Gateway: Authorization Failed')
      end
    end

    # override
    # purchase is used when pre auth disabled
    def purchase(_amount, _source, gateway_options = {})
      _, payment_number = gateway_options[:order_id].split('-')
      payment = Spree::Payment.find_by(number: payment_number)

      checker = check_transaction(payment)
      payment.update(transaction_response: checker.json_response)

      success = checker.success?
      params = {}

      success, params[:payout] = confirm_payouts(payment) if success && payout_total_from_response(payment).present?

      if success
        ActiveMerchant::Billing::Response.new(true, 'Payway Gateway: Purchased', params)
      else
        ActiveMerchant::Billing::Response.new(false, 'Payway Gateway: Purchasing Failed', params)
      end
    end

    # override
    def capture(_amount, _response_code, gateway_options)
      _, payment_number = gateway_options[:order_id].split('-')
      payment = Spree::Payment.find_by(number: payment_number)

      success = true
      params = {}

      success, params[:pre_auth] = complete_pre_auth(payment) if enable_pre_auth?
      success, params[:payout] = confirm_payouts(payment) if success && payout_total_from_response(payment).present?

      if success
        ActiveMerchant::Billing::Response.new(true, 'Payway Gateway: Captured', params)
      else
        ActiveMerchant::Billing::Response.new(false, 'Payway Gateway: Capture Failed', params)
      end
    end

    # override
    def void(_response_code, gateway_options)
      _, payment_number = gateway_options[:order_id].split('-')
      payment = Spree::Payment.find_by(number: payment_number)

      if enable_pre_auth?
        params = {}
        success, params[:pre_auth] = cancel_pre_auth(payment)

        if success
          ActiveMerchant::Billing::Response.new(true, 'Payway Gateway: Pre-authorization successfully canceled.', params)
        else
          ActiveMerchant::Billing::Response.new(false, 'Payway Gateway: Failed to cancel pre-authorization.', params)
        end
      else
        ActiveMerchant::Billing::Response.new(true, 'Payway Gateway: Payment has been voided.')
      end
    end

    # override
    def cancel(_response_code, _payment)
      ActiveMerchant::Billing::Response.new(true, 'Payway Gateway: Payment has been canceled.')
    end

    private

    def check_transaction(payment)
      checker = Vpago::PaywayV2::TransactionStatus.new(payment)
      checker.call
      checker
    end

    def cancel_pre_auth(payment)
      canceler = Vpago::PaywayV2::PreAuthCanceler.new(payment)
      canceler.call

      [canceler.success?, canceler.request_data]
    end

    def complete_pre_auth(payment)
      completer = Vpago::PaywayV2::PreAuthCompleter.new(payment)

      completer.call
      [completer.success?, completer.request_data]
    end

    def confirm_payouts(payment)
      expect_payout_total = payment.payouts.sum(:amount)
      payout_total = payout_total_from_response(payment)

      confirmed = false

      if payout_total == expect_payout_total
        payment.payouts.find_each { |payout| payout.update!(state: :confirmed) }
        confirmed = true
      end

      payout_params = { payout_total: payout_total, expect_payout_total: expect_payout_total }
      [confirmed, payout_params]
    end

    def payout_total_from_response(payment)
      payouts_response = payment.transaction_response&.dig('payout')

      return nil if payouts_response.nil? || !payouts_response.is_a?(Array) || payouts_response.empty?

      payouts_response.map { |payout| payout['amt'].to_f || 0 }.sum
    end
  end
end
