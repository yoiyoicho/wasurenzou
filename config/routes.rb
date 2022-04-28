Rails.application.routes.draw do
  root to: 'home#top'
  post 'callback', to: 'line#callback'
end
