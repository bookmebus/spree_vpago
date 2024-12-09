Spree::Core::Engine.add_routes do
  # Add your extension routes here

  resource :payway_card_popups, only: [:show]
  resource :payway_v2_card_popups, only: [:show]
  resource :wing_redirects, only: [:show]
  resource :acleda_redirects, only: [:show]

  resources :payway_results, only: [] do
    collection do
      get :success
      get :failed
    end
  end

  namespace :wing do
    resources :transactions, only: [:show]
  end

  namespace :webhook do
    resource :payways, only: [] do
      match 'return', to: 'payways#return', via: %i[get post]
      get 'continue', to: 'payways#continue'

      match 'v2_return', to: 'payways#v2_return', via: %i[get post]
      get 'v2_continue', to: 'payways#v2_continue'
    end

    resource :acledas, only: [] do
      get 'success', to: 'acledas#success'
      get 'error', to: 'acledas#error'
      match 'return', to: 'acledas#return', via: :post
    end

    resource :acleda_mobiles, only: [] do
      match 'return', to: 'acleda_mobiles#return', via: :post
    end

    resources :wings, only: [:create] do
      match 'return', to: 'wings#return', via: %i[get post]
    end
  end

  namespace :api, defaults: { format: 'json' } do
    namespace :v2 do
      namespace :storefront do
        resource :checkout, controller: :checkout do
          get :payment_redirect
          patch :request_update_all_payments
          patch :request_update_payment
        end
      end
    end
  end

  namespace :admin do
    resources :payment_wing_sdk_queriers, only: [:show]
    resources :payment_wing_sdk_checkers, only: [:update]
    resources :payment_wing_sdk_markers, only: [:update]

    resources :payment_payway_queriers, only: [:show]
    resources :payment_payway_checkers
    resources :payment_payway_markers

    resources :products do
      resources :payout_profile_products
    end

    resources :orders do
      resources :payouts
    end

    resources :shipping_methods do
      resources :payout_profile_shipping_methods
    end

    resources :payout_profiles do
      member do
        post :verify_with_bank
      end
    end
  end
end
