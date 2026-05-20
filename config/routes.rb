# frozen_string_literal: true

Rails.application.routes.draw do
  get 'users/index'
  devise_for :users
  # For details on the DSL available within this file, see https://guides.rubyonrails.org/routing.html
  root 'users#index'

  resources :users, only: [:index] do
    collection do
      get :search
    end
  end

  resources :conversations, only: %i[create show] do
    resources :messages, only: %i[index create]
  end
end
