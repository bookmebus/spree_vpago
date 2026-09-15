module Vpago
  module AcledaMiniApp
    # ACLEDA Mini App checkout. Reuses ACLEDA V2's openSessionV2 flow to obtain a
    # deeplink, which is passed to the ACLEDA super-app via the acledaJSBridge
    # (startPayment) instead of redirecting the page.
    class Checkout < Vpago::AcledaV2::Checkout
      # The mini app always uses the deeplink + JS bridge, regardless of the
      # gateway's configured mode.
      def deeplink?
        true
      end

      # The deeplink string handed to
      #   acledaJSBridge.call('startPayment', { acleda_deeplink: ... })
      # Ensures openSessionV2 has run (persisting paymentTokenid for later
      # getTxnStatus verification) before returning the deeplinkUrl.
      def acleda_deeplink
        call if @response.nil?
        deeplink_url
      end
    end
  end
end
