Rails.application.routes.draw do
  post 'make_graph' => 'home#make_graph'
  get 'values_for_analytics_option' => 'application#values_for_analytics_option'

  get 'contact' => 'home#contact'
  post 'contact' => 'home#contact'
  get 'recommend' => 'home#recommend'
  post 'recommend' => 'home#recommend'

  root to: 'home#index', via: [:get]

  match "/404", :to => "errors#error", via: :all
  match "/500", :to => "errors#error", via: :all
end
