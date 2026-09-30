module Vpago
  module AddressDecorator
    # override
    def require_phone?
      false
    end
  end
end

Spree::Address.prepend(Vpago::AddressDecorator) unless Spree::Address.included_modules.include?(Vpago::AddressDecorator)
