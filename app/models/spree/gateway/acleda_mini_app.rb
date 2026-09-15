module Spree
  # ACLEDA Mini App payment method.
  #
  # Reuses the ACLEDA V2 integration in deeplink mode: the deeplink produced by
  # ACLEDA's openSessionV2 API is handed to the ACLEDA super-app through the
  # `acledaJSBridge` (startPayment) instead of redirecting the page. Server-side
  # verification reuses AcledaV2's #check_transaction (getTxnStatus).
  class Gateway::AcledaMiniApp < Gateway::AcledaV2
    # override: partial to render in admin / checkout form lookup
    def method_type
      'acleda_mini_app'
    end

    # The mini app always uses the deeplink + JS bridge, so admins don't need to
    # set the ACLEDA V2 mode.
    def deeplink?
      true
    end
  end
end
