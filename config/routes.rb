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

  namespace :mini_app do
    # ACLEDA calls POST /mini_app/acleda with { phone, first_name, last_name }
    # and receives a session-based miniAppUrl.
    resources :acleda, only: [:create], controller: 'acledas'

    # Wing Mini App WebView entry. Wing opens GET /mini_app/wing cold and the page
    # itself authenticates via getProfile.
    resource :wing, only: %i[show create], controller: 'wings' do
      # Wing's settlement webhook: #callback verifies the payment via PaymentFinder and
      # queues PaymentProcessorJob to complete the order unless it is already paid.
      post :callback, on: :collection
    end
  end

  resource :vpago_payments do
    collection do
      get :checkout
      get :processing
      get :success

      match :check_transaction, via: %i[get]
      match :process_payment, via: %i[get post]
      match :true_money_process_payment, via: %i[get post]
    end
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

    resources :payment_acleda_v2_queriers, only: [:show]
    resources :payment_acleda_v2_checkers, only: [:update]

    resources :payment_vattanac_queriers, only: [:show]
    resources :payment_vattanac_checkers, only: [:update]

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

    resources :suspicious_orders, only: [:index] do
      member do
        get :payments
        post 'payments/:payment_number/check_transaction', action: :check_transaction, as: :check_transaction
      end
    end
  end
end
