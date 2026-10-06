# frozen_string_literal: true

require "test_helper"

class ConfigurationTest < Minitest::Test
  def setup
    @configuration = RecordingStudioBrands::Configuration.new
  end

  def test_merge_updates_known_attributes
    @configuration.merge!(authentication_method: :authenticate_admin!, current_actor_method: :current_admin)

    assert_equal :authenticate_admin!, @configuration.authentication_method
    assert_equal :current_admin, @configuration.current_actor_method
  end

  def test_merge_ignores_unknown_keys
    @configuration.merge!(unknown_key: "ignored", current_actor_method: :current_admin)

    refute_respond_to @configuration, :unknown_key
    assert_equal :current_admin, @configuration.current_actor_method
  end

  def test_merge_with_non_enumerable_is_noop
    @configuration.merge!(nil)

    assert_equal :authenticate_user!, @configuration.authentication_method
    assert_equal :current_user, @configuration.current_actor_method
  end

  def test_merge_accepts_string_keys
    @configuration.merge!("authentication_method" => "authenticate_admin!")

    assert_equal "authenticate_admin!", @configuration.authentication_method
  end

  def test_to_h_reports_registered_hook_counts
    @configuration.hooks.before_initialize { nil }
    @configuration.hooks.before_initialize { nil }
    @configuration.hooks.after_service { nil }

    result = @configuration.to_h

    assert_equal 2, result.fetch(:hooks_registered).fetch(:before_initialize)
    assert_equal 1, result.fetch(:hooks_registered).fetch(:after_service)
  end

  def test_configure_without_block_is_safe
    RecordingStudioBrands.configure

    assert_kind_of RecordingStudioBrands::Configuration, RecordingStudioBrands.configuration
  end
end
