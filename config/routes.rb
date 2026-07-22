Rails.application.routes.draw do
  namespace :admin do
    resources :users
    resources :zonings
    resources :imports
    resources :integration_filleas
    resources :integration_flcs

    root to: "users#index"
  end

  devise_for :users

  resources :zonings do
    member do
      get :confirm_destroy
    end
  end
  resources :imports, only: %i[index new create show]
  resources :integration_filleas do
    member do
      get :confirm_destroy
    end
  end
  resources :integration_flcs do
    member do
      get :confirm_destroy
    end
  end
  resources :integration_flc_uploads, only: %i[new create]
  resources :statistics, only: %i[index]

  mount ActionCable.server => "/cable"

  get "credits", to: "pages#credits"

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  # Defines the root path route ("/")
  root "pages#index"
end
