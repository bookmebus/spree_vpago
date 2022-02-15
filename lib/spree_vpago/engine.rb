module SpreeVpago
  class Engine < Rails::Engine
    require 'spree/core'
    isolate_namespace Spree
    engine_name 'spree_vpago'

    config.autoload_paths += %W[#{config.root}/lib]
    
    # use rspec for tests
    config.generators do |g|
      g.test_framework :rspec
    end

    config.assets.precompile += [
      'vpago/payway/*',
    ]

    def self.activate
      ::Rails.application.config.spree.payment_methods << Spree::Gateway::Payway
      ::Rails.application.config.spree.payment_methods << Spree::Gateway::PaywayV2
      ::Rails.application.config.spree.payment_methods << Spree::Gateway::WingSdk
      ::Rails.application.config.spree.payment_methods << Spree::Gateway::Acleda
      ::Rails.application.config.spree.payment_methods << Spree::Gateway::AcledaMobile

      Dir.glob(File.join(File.dirname(__FILE__), '../../app/**/*_decorator*.rb')) do |c|
        Rails.configuration.cache_classes ? require(c) : load(c)
      end


      Spree::PermittedAttributes.source_attributes << :payment_option
      Spree::PermittedAttributes.source_attributes << :payment_id
      Spree::PermittedAttributes.source_attributes << :payment_method_id

      Spree::Api::ApiHelpers.payment_source_attributes << :payment_option
      Spree::Api::ApiHelpers.payment_source_attributes << :payment_id
      Spree::Api::ApiHelpers.payment_source_attributes << :payment_method_id
    end

    config.to_prepare(&method(:activate).to_proc)
  end
end
