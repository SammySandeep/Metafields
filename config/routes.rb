Rails.application.routes.draw do
  resources :metafields do
    collection { post :import }
  end
  root 'metafields#index'
end
