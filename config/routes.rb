Rails.application.routes.draw do
  # For details on the DSL available within this file, see http://guides.rubyonrails.org/routing.html
  root "application#index"
  get "cari", controller: "application"
  get "order", controller: "application"
  post "kirim_orderan", controller: "application"
  get "penyimpanan", controller: "application"
  get "pembuat_socket", controller: "application"
  post "pembuat_socket", controller: "application"
end
