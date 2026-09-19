Rails.application.routes.draw do
  root "tasks#index"
  resources :tasks, except: :show do
    patch :completion, on: :member
  end
  get "up" => "rails/health#show", as: :rails_health_check
end
