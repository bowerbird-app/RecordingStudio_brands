# frozen_string_literal: true

RecordingStudioBrands::Engine.routes.draw do
  resources :recordings, only: [] do
    resources :brands, only: %i[index new create show edit update], shallow: true do
      resource :logo, only: :update
    end
  end
end
