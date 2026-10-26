# Wing's partner credentials come from SpreeCmCommissioner::WingMiniApp::Config, which lives
# in the commissioner gem. That gem isn't loaded in this engine's dummy app, so the constant
# has to stand in here — it is only two ENV reads, and both gems share one source of truth.
module WingMiniAppCredentials
  def stub_wing_mini_app_credentials(app_id:, secret_api_key:)
    config = Class.new do
      class << self
        attr_accessor :app_id, :secret_api_key
      end
    end
    config.app_id = app_id
    config.secret_api_key = secret_api_key

    stub_const('SpreeCmCommissioner::WingMiniApp::Config', config)
  end
end

RSpec.configure do |config|
  config.include WingMiniAppCredentials
end
