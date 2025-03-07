lib = File.expand_path('lib', __dir__)
$LOAD_PATH.unshift lib unless $LOAD_PATH.include?(lib)

require 'spree_vpago/version'

Gem::Specification.new do |s|
  s.platform    = Gem::Platform::RUBY
  s.name        = 'spree_vpago'
  s.version     = SpreeVpago.version
  s.summary     = 'Cambodian Payment Gateway Integration for Spree Commerce'
  s.description = 'This Spree Commerce extension integrates Cambodian payment gateways, supporting ABA Bank, Acleda Bank, and Wing for secure and seamless transactions.'
  s.required_ruby_version = '>= 3.2.0'

  s.author    = 'You'
  s.email     = 'you@example.com'
  s.homepage  = 'https://github.com/your-github-handle/spree_vpago'
  s.license = 'BSD-3-Clause'

  s.files = `git ls-files`.split("\n").reject { |f| f.match(/^spec/) && !f.match(%r{^spec/fixtures}) }
  s.require_path = 'lib'
  s.requirements << 'none'

  spree_version = '>= 4.5'
  s.add_dependency 'faraday'
  s.add_dependency 'google-cloud-firestore'
  s.add_dependency 'spree_api', spree_version
  s.add_dependency 'spree_backend', spree_version
  s.add_dependency 'spree_core', spree_version
  s.add_dependency 'spree_extension'
  s.add_dependency 'spree_multi_vendor', '>= 2.4.1'

  s.metadata['rubygems_mfa_required'] = 'true'
end
