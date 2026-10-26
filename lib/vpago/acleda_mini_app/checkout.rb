module Vpago
  module AcledaMiniApp
    # ACLEDA Mini App checkout. Reuses ACLEDA V2's openSessionV2 flow to obtain the deeplink
    # the payment page opens, instead of redirecting the page to ACLEDA.
    class Checkout < Vpago::AcledaV2::Checkout
      # The mini app always pays by deeplink, regardless of the gateway's configured mode.
      def deeplink?
        true
      end

      # The deeplink _acleda_mini_app.html.erb opens. Ensures openSessionV2 has run
      # (persisting paymentTokenid for the later getTxnStatus check) before returning it.
      def acleda_deeplink
        call if @response.nil?
        deeplink_url
      end
    end
  end
end
