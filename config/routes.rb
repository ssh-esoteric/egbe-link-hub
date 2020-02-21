Rails.application.routes.draw do
  match 'links/:id/api', to: 'links#api', via: ['GET', 'PUT']

  # For details on the DSL available within this file, see https://guides.rubyonrails.org/routing.html
end
