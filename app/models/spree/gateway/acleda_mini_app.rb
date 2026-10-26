module Spree
  # ACLEDA Mini App payment method.
  #
  # Reuses the ACLEDA V2 integration in deeplink mode: openSessionV2 returns a deeplink the
  # payment page opens as a top-frame navigation, which ACLEDA's own WebView turns into an app
  # launch. Server-side verification reuses AcledaV2's #check_transaction (getTxnStatus).
  class Gateway::AcledaMiniApp < Gateway::AcledaV2
    # override: partial to render in admin / checkout form lookup
    def method_type
      'acleda_mini_app'
    end

    # The mini app always pays by deeplink, so admins don't need to set the ACLEDA V2 mode.
    def deeplink?
      true
    end
  end
end
