Rails.application.routes.draw do
  post 'make_graph' => 'home#make_graph'
  get 'values_for_analytics_option' => 'application#values_for_analytics_option'

  get 'webhook' => 'webhooks#confirm_webhook'
  post 'webhook' => 'webhooks#webhook_notification'
  post 'install_webhooks' => 'home#install_webhooks'
  # GET graph.facebook.com/145634995501895/subscribed_apps
  # curl -i -X POST \
  #   -d "access_token=page-access-token" \
  #   "https://graph.facebook.com/v2.11/1353269864728879/subscribed_apps"

  get 'facebook_data' => 'application#facebook_data'

  get 'contact' => 'home#contact'
  post 'contact' => 'home#contact'
  get 'recommend' => 'home#recommend'
  post 'recommend' => 'home#recommend'


  root to: 'home#index', via: [:get]

  match "/404", :to => "errors#error", via: :all
  match "/500", :to => "errors#error", via: :all
end
