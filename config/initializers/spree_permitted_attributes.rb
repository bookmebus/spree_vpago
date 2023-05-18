module Spree
  module PermittedAttributes
    @@source_attributes += %i[payment_option payment_id payment_method_id]
  end
end