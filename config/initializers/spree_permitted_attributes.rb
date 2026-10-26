module Spree
  module PermittedAttributes
    @@source_attributes += %i[payment_option payment_id payment_method_id] # rubocop:disable Style/ClassVars
  end
end
