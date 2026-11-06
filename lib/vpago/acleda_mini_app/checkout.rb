module Vpago
  module AcledaMiniApp
    # ACLEDA Mini App checkout. Reuses ACLEDA V2's openSessionV2 flow to obtain the deeplink
    # the payment page opens, instead of redirecting the page to ACLEDA.
    class Checkout < Vpago::AcledaV2::Checkout
      ANDROID_APP_HOST = 'com.domain.acledabankqr'.freeze

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

      # The app address ACLEDA's deeplink landing page opens on Android, built from the
      # deeplink's own query.
      #
      # Opened instead of the deeplink: 500 ms after opening the app, that landing page sends the
      # WebView to the Play Store unless the page was hidden, and inside ACLEDA's app the wallet
      # is a dialog that never hides it — so the customer comes back to a Play Store error page.
      # ACLEDA's WebView opens the wallet for this address without loading anything, so our page
      # stays behind the wallet.
      def acleda_android_app_link
        deeplink = acleda_deeplink
        return nil if deeplink.blank?

        query = URI.parse(deeplink).query
        # Re-serialized the way the landing page does (URLSearchParams#toString).
        params = query.present? ? "?#{URI.encode_www_form(URI.decode_www_form(query))}" : ''

        "https://#{ANDROID_APP_HOST}/app#{params}"
      rescue URI::InvalidURIError, ArgumentError
        nil
      end
    end
  end
end
