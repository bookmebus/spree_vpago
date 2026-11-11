module Spree
  # Shared by every mini app controller. What lives here is whatever a mini app needs from the
  # request or gives back in the response, rather than anything one partner does on its own —
  # today the gate its session service runs the caller through, built from the two things only
  # the request knows, and the status a refusal answers with.
  module MiniAppConcern
    extend ActiveSupport::Concern

    private

    def session_gate(provider)
      SpreeCmCommissioner::MiniAppProvider::SessionGate.new(
        provider: provider,
        api_key: request.headers['X-Api-Key'],
        ip: request.remote_ip
      )
    end

    # A cap or a blocked address is not the payload being wrong, so each answers with its
    # own status and the partner can tell them apart.
    def failure_status(result)
      (result.value.is_a?(Hash) && result.value[:status]) || :unprocessable_entity
    end
  end
end
