require 'spec_helper'

RSpec.describe Spree::Dependencies do
  it { expect(::Spree::Dependencies.payment_create_service.constantize).to eq Vpago::Payments::FindOrCreate }
  it { expect(::Spree::Api::Dependencies.storefront_payment_create_service.constantize).to eq Vpago::Payments::FindOrCreate }
end
