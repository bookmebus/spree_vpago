Spree::Core::Engine.add_routes do
  # Add your extension routes here

  resource :payway_card_popups, only: [:show]
  resource :wing_redirects, only: [:show]

  resources :payment_results, only: [] do
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

    resources :wings, only: [:create] do
      match 'return', to: 'wings#return', via: [:get, :post]
    end
  end

  namespace :admin do
    resources :payment_wing_sdk_queriers, only: [:show]
    resources :payment_wing_sdk_checkers, only: [:update]
    resources :payment_wing_sdk_markers, only: [:update]

    resources :payment_payway_queriers, only: [:show]
    resources :payment_payway_checkers
    resources :payment_payway_markers
  end
end
