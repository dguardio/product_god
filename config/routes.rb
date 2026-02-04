Rails.application.routes.draw do
  get 'data_sources/index'
  get 'chat_sessions/index'
  get 'chat_sessions/show'
  get 'chat_sessions/create'
  get 'chat_sessions/update'
  get 'users/show'
  resources :chat_sessions, only: [:index, :show, :create, :update, :destroy]
  
  resources :data_sources, only: [:index] do
    collection do
      post :create_pdf
      post :create_slack
      post :create_web
      post :create_episode
    end
  end
  
  resources :whats_app_chats, only: [:index, :new, :create, :show]
  
  # Public profile route
  get '/u/:username', to: 'users#show', as: :user_profile
  
  devise_for :users

  resources :board_meetings, only: [:new, :create, :show] do
    resources :messages, only: [:create], module: :board_meetings
  end
  resources :playbooks, only: [:index, :new, :create, :show]
  get 'knowledge_graph/index'
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  get "/search", to: "search#index"
  post "/search", to: "search#query"

  resources :knowledge_graph, only: [:index] do
    collection do
      get :search
      get :visualize
    end
  end
  # Defines the root path route ("/")
  root "search#index"
end
