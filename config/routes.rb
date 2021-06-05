Spree::Core::Engine.add_routes do
  # Add your extension routes here

  resource :payway_card_popups, only: [:show]

  resources :payway_results, only: [] do
    collection do
      get :success
      get :failed
    end
  end

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
