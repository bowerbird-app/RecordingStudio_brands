# frozen_string_literal: true

module RecordingStudioBrands
  class Configuration
    attr_accessor :authentication_method, :current_actor_method, :mount_path
    attr_reader :hooks

    def initialize
      @authentication_method = :authenticate_user!
      @current_actor_method = :current_user
      @mount_path = "/recording_studio_brands"
      @hooks = RecordingStudio::Hooks.new
    end

    def to_h
      {
        authentication_method: authentication_method,
        current_actor_method: current_actor_method,
        mount_path: mount_path,
        hooks_registered: hooks.instance_variable_get(:@registry).transform_values(&:size)
      }
    end

    def merge!(hash)
      return unless hash.respond_to?(:each)

      hash.each do |k, v|
        key = k.to_s
        setter = "#{key}="
        public_send(setter, v) if respond_to?(setter)
      end
    end
  end
end
