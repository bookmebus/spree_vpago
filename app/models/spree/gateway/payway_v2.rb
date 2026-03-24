module Spree
  class Gateway::PaywayV2 < PaymentMethod
    ABAPAY_KHQR_DEEPLINK_OPTIONS = %w[open_both open_deeplink_only open_checkout_url_only].freeze
    PAYMENT_OPTIONS = %w[abapay_khqr_deeplink abapay_khqr cards wechat alipay].freeze

    preference :host, :string
    preference :api_key, :string
    preference :merchant_id, :string
    preference :payment_option, :string
    preference :transaction_fee_fix, :string
    preference :transaction_fee_percentage, :string
    preference :public_key, :text
    preference :abapay_khqr_deeplink_option, :string, default: 'open_both'

    # For reviewing purpose, not used in actual flow
    preference :reviewing_mode, :boolean, default: false

    validates :preferred_public_key, presence: true, if: :enable_pre_auth?
    validates :preferred_abapay_khqr_deeplink_option, inclusion: { in: ABAPAY_KHQR_DEEPLINK_OPTIONS }, if: :abapay_khqr_deeplink?
    validates :preferred_payment_option, inclusion: { in: PAYMENT_OPTIONS }

    def reviewing_mode?
      preferred_reviewing_mode
    end

    # override: partial to render in admin
    def method_type
      'payway_v2'
    end

    def abapay_khqr_deeplink?
      preferred_payment_option == 'abapay_khqr_deeplink'
    end

    def open_abapay_deeplink?
      preferred_abapay_khqr_deeplink_option.in?(%w[open_both open_deeplink_only])
    end

    def open_checkout_url?
      preferred_abapay_khqr_deeplink_option.in?(%w[open_both open_checkout_url_only])
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

      params = { check: { response: checker.json_response } }

      if checker.success?
        ActiveMerchant::Billing::Response.new(true, 'Payway Gateway: Authorized', params)
      else
        ActiveMerchant::Billing::Response.new(false, 'Payway Gateway: Authorization Failed', params)
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

    def check_transaction(payment)
      # ABA requires the use of the v2 API, but it does not yet support payout responses.
      # Until v2 fully supports payouts, we fall back to v1 when payouts are enabled.
      # Otherwise, we use v2 by default.
      checker = if payment.preload_payout_ids.any?
                  Vpago::PaywayV2::TransactionStatus.new(payment)
                else
                  Vpago::PaywayV2::TransactionStatusV2.new(payment)
                end
      checker.call
      checker
    end

    private

    def cancel_pre_auth(payment)
      canceler = Vpago::PaywayV2::PreAuthCanceler.new(payment)
      canceler.call

      data = { request: canceler.request_data, response: canceler.json_response }
      [canceler.success?, data]
    end

    def complete_pre_auth(payment)
      completer = Vpago::PaywayV2::PreAuthCompleter.new(payment)
      completer.call

      data = { request: completer.request_data, response: completer.json_response }
      [completer.success?, data]
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

      payouts_response.map { |payout| payout['amt'].to_f }.sum
    end
  end
end
