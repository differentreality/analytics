Rails.application.routes.draw do
  devise_for :users, controllers: { omniauth_callbacks: 'users/omniauth_callbacks'},
                     path: 'user'
  devise_scope :user do
    delete "/users/sign_out" => "devise/sessions#destroy"
  end

  resources :users, only: [:edit, :update, :destroy] do
    get :get_pages
  end

  post 'renew_fans' => 'fans#renew_fans'
  get 'add_time_period' => 'posts#add_time_period'
  resources :pages do
    resources :posts, only: [:index, :show, :new] do
      member do
        post :make_graph
      end
    end
    resources :events, only: [:index, :show, :new]
    resources :reactions, only: [:index, :new]
    get 'fans/city' => 'fans#city'
    get 'fans/age' => 'fans#age'
  end

  post 'user_pages' => 'application#user_pages'

  resources :people
  namespace :api, defaults: { format: 'json' } do
    resources :posts, only: [:new, :update]
    get 'initialize_posts' => 'posts#initialize'
    get 'page_fans_city' => 'pages#page_fans_city'
  end

  post 'trending_graph' => 'posts#trending_graph'
  post 'make_graph' => 'application#make_graph'
  post 'make_overall_graph' => 'application#make_overall_graph'
  post 'make_overall_graph_time_periods' => 'application#make_overall_graph_time_periods'
  get 'values_for_analytics_option' => 'application#values_for_analytics_option'

  post 'update_overall_statistics_table' => 'application#update_overall_statistics_table'
  post 'yearly_content' => 'application#yearly_content'

  get 'webhook' => 'webhooks#confirm_webhook'
  post 'webhook' => 'webhooks#webhook_notification'
  # post 'install_webhooks' => 'home#install_webhooks'

  get 'facebook_data' => 'application#facebook_data'

  get 'contact' => 'home#contact'
  post 'contact' => 'home#contact'
  get 'recommend' => 'home#recommend'
  post 'recommend' => 'home#recommend'

  root to: 'pages#index', via: [:get]

  match "/404", :to => "errors#error", via: :all
  match "/500", :to => "errors#error", via: :all
end
