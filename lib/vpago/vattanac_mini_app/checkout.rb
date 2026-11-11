module Vpago
  module VattanacMiniApp
    class Checkout < Base
      def signed_payload 
        Vpago::VattanacMiniAppDataHandler.new.encrypted_data(payload)
      end
    end
  end
end
