Spree::Core::Engine.add_routes do
  # Add your extension routes here
  namespace :webhook do
    resource :payways, only: [] do
      match 'return', to: 'payways#return', via: [:get, :post]
      get 'continue', to: 'payways#continue'
    end
  end

  namespace :admin do
    resources :payment_payway_queriers, only: [:show]
    resources :payment_payway_checkers
    resources :payment_payway_markers
  end
end
