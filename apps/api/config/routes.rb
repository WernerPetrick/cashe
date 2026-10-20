Rails.application.routes.draw do
  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  get "up" => "rails/health#show", as: :rails_health_check

  namespace :api do
    namespace :v1 do
      resource :session, only: :create
      get "me", to: "me#show"

      resources :places, only: %i[index create]
      resources :gift_claims, only: :create

      resources :wallets, only: %i[index show create] do
        scope module: :wallets do
          resources :deposits, only: :create
          resources :presence_pings, only: :create
          resources :spends, only: :create
          resources :ledger_entries, only: :index
          resource :cancellation, only: :create
        end
      end
    end
  end
end
