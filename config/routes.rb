Rails.application.routes.draw do
  get "up" => "rails/health#show", as: :rails_health_check

  root "home#index"

  get "guide", to: "guide#index", as: :guide

  get "tutorial", to: "tutorials#index", as: :tutorial
  get "tutorial/debug", to: "tutorials#debug", as: :tutorial_debug
  get "tutorial/profiles/:id", to: "tutorials#show", as: :tutorial_profile

  get "login", to: "sessions#new", as: :login
  post "login", to: "sessions#create"
  delete "logout", to: "sessions#destroy", as: :logout

  namespace :admin do
    get "calendar", to: "calendar#index"
    resources :details, only: [ :show ]
    get "demo_data", to: "demo_data#index", as: :demo_data
    post "demo_data/authenticate", to: "demo_data#authenticate", as: :authenticate_demo_data
    delete "demo_data/session", to: "demo_data#relock", as: :relock_demo_data
    post "demo_data/batches", to: "demo_data#create", as: :demo_data_batches
    patch "demo_data/reset", to: "demo_data#reset", as: :reset_demo_data
    delete "demo_data", to: "demo_data#destroy"
  end

  namespace :provider do
    get "detail", to: "detail#show"
    resources :work_requests, only: %i[show new create edit update]
  end

  # 自動仮割当と全解除は状態を変更するためGETでは公開しない。
  post "work_requests/draft", to: "work_requests#draft", as: :draft
  delete "work_requests/unassign_all", to: "work_requests#unassign_all", as: :unassign_all
  get "work_requests/shift", to: "work_requests#shift", as: :work_requests_shift
  get "work_requests/export", to: "work_requests#export", as: :export_work_requests

  resources :work_requests, only: %i[index show edit update] do
    post :assign, on: :member
    delete :unassign, on: :member
    patch :confirm, on: :member
  end

  delete "work_requests/:work_request_id/assignments/:id",
    to: "work_requests#destroy_assignment",
    as: :work_request_assignment

  resources :details_of_shifts, only: %i[index show edit update]
  resources :availabilities, only: %i[index new create edit update destroy]
  resources :list_views, only: [ :index ] do
    get :confirmed, on: :collection
    patch :confirm, on: :member
    patch :unconfirm, on: :member
  end
  resources :change_events, only: %i[index update]
  resources :staff_members, only: [ :index ]

  get "examples/local-data", to: "examples#local_data", as: :examples_local_data

  if Rails.env.development? && ENV["ENABLE_CHANGE_EVENT_DEBUG"] == "true"
    namespace :debug do
      resources :change_events, only: %i[index create destroy]
    end
  end
end
