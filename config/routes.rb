Spree::Core::Engine.add_routes do
  # Add your extension routes here
  namespace :webhook do
    resource :payways, only: [] do
      match 'return', to: 'payways#return', via: [:get, :post]
      get 'continue', to: 'payways#continue'
    end
  end
end
