# frozen_string_literal: true

module Vpago
  module LogEntryDecorator
    def parsed_details
      @details ||= if Gem::Version.new(RUBY_VERSION) >= Gem::Version.new('3.1.0')
                     YAML.safe_load(details, permitted_classes: permitted_classes_for_yaml, aliases: true)
                   else
                     YAML.safe_load(details, permitted_classes_for_yaml)
                   end
    end

    private

    def permitted_classes_for_yaml
      [
        ActiveMerchant::Billing::Response,
        Symbol,
        Hash
      ]
    end
  end
end

Spree::LogEntry.prepend(Vpago::LogEntryDecorator) if Spree::LogEntry.included_modules.exclude?(Vpago::LogEntryDecorator)
