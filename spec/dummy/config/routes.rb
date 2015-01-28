Rails.application.routes.draw do

  mount Cul::Omniauth::Engine => "/cul_omniauth"
end
