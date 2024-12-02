module Vpago
  module PaywayV2
    class PreAuthHandler
      def capture_pre_auth(payment)
        Vpago::PaywayV2::PreAuthCompleter.new(payment).call
      end

      def cancel_pre_auth(payment)
        Vpago::PaywayV2::PreAuthCanceler.new(payment).call
      end
    end
  end
end