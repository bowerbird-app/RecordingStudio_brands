# frozen_string_literal: true

module RecordingStudioBrands
  class ApplicationController < (defined?(::ApplicationController) ? ::ApplicationController : ActionController::Base)
    include RecordingStudio::UsesDefaultLayout if defined?(RecordingStudio::UsesDefaultLayout)

    # Isolated engines look up layouts in their own namespace first. Prepend the
    # host and Recording Studio view paths so `recording_studio/default_layout` resolves.
    if defined?(Rails.application) && Rails.application.respond_to?(:root)
      prepend_view_path Rails.application.root.join("app/views")
    end
    append_view_path RecordingStudio::Engine.root.join("app/views") if defined?(RecordingStudio::Engine)

    layout "recording_studio/default_layout" if defined?(RecordingStudio::UsesDefaultLayout)

    protect_from_forgery with: :exception

    before_action :authenticate_brands_actor!

    helper_method :brand_home_path, :can_edit?

    private

    def authenticate_brands_actor!
      method_name = RecordingStudioBrands.configuration.authentication_method
      return send(method_name) if method_name && respond_to?(method_name, true)

      head :unauthorized
    end

    def brands_actor
      method_name = RecordingStudioBrands.configuration.current_actor_method
      send(method_name) if method_name && respond_to?(method_name, true)
    end

    def authorize_recording!(recording, role:)
      head :forbidden unless RecordingStudioAccessible.authorized?(actor: brands_actor, recording:, role:)
    end

    def can_edit?(recording)
      RecordingStudioAccessible.authorized?(actor: brands_actor, recording:, role: :edit)
    end

    def load_brand(id, role:)
      @brand_recording = RecordingStudio::Recording.find_by!(id:, recordable_type: BRAND_TYPE)
      @parent = @brand_recording.parent_recording
      @mount = Mount.for(@parent) || raise(ActiveRecord::RecordNotFound)
      authorize_recording!(@brand_recording, role:)
    end

    def brand_home_path(brand_recording)
      case @mount
      in Mount::One then recording_brands_path(@parent)
      in Mount::Many then brand_path(brand_recording)
      end
    end
  end
end
