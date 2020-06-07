Rails.application.routes.draw do
  get '/', to: redirect('/links/')

  get 'links/', to: 'links#index'
  post 'links/', to: 'links#create'

  get 'links/:id', to: 'links#read'
  post 'links/:id', to: 'links#update'

  match 'links/:id/api', to: 'links#api', via: ['GET', 'PUT']

  # For details on the DSL available within this file, see https://guides.rubyonrails.org/routing.html
end
