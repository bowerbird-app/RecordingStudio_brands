# frozen_string_literal: true

require "test_helper"

class BrandGuardConcurrencyTest < ActiveSupport::TestCase
  # Each thread commits on its own connection, which the rollback-per-test
  # transaction would hide. Teardown deletes every row the test wrote.
  self.use_transactional_tests = false

  setup do
    @brand_options = RecordingStudio.capability_options(:brand, for: Workspace)
    RecordingStudio.set_capability_options(:brand, on: Workspace, allows: :one)
    @workspace = RecordingStudio.root_recording_for(Workspace.create!(name: "Concurrent Brand Workspace"))
    @brands = [ "Nike", "Dove" ].map { |name| RecordingStudioBrands::Brand.create!(name:) }
  end

  teardown do
    RecordingStudio.set_capability_options(:brand, on: Workspace, **@brand_options) if @brand_options
    recording_ids = RecordingStudio::Recording.unscoped.where(root_recording_id: @workspace.id).ids
    RecordingStudio::Event.where(recording_id: recording_ids).delete_all
    RecordingStudio::Recording.unscoped.where(id: recording_ids).where.not(id: @workspace.id).delete_all
    RecordingStudio::Recording.unscoped.where(id: @workspace.id).delete_all
    RecordingStudioBrands::Brand.where(id: @brands.map(&:id)).delete_all
    Workspace.where(id: @workspace.recordable_id).delete_all
  end

  test "a direct create waiting on the workspace sees the brand committed ahead of it" do
    inserted = Queue.new
    release = Queue.new

    first = in_thread do
      RecordingStudio::Recording.transaction do
        RecordingStudio::Recording.create!(parent_recording: @workspace, recordable: @brands.first)
        inserted << true
        release.pop
      end
    end
    assert inserted.pop(timeout: 5), "the first create never inserted"

    second = in_thread do
      RecordingStudio::Recording.create!(parent_recording: @workspace, recordable: @brands.second)
    rescue RecordingStudioBrands::BrandLimitReached => error
      error
    end
    wait_until { lock_waiters.positive? || !second.alive? }
    release << true
    first.join

    assert_kind_of RecordingStudioBrands::BrandLimitReached, second.value
    assert_equal [ @brands.first.id ],
                 RecordingStudio::Recording.where(parent_recording: @workspace).pluck(:recordable_id)
  ensure
    release << true
    first&.join
    second&.join
  end

  private

  def in_thread(&)
    Thread.new { ActiveRecord::Base.connection_pool.with_connection(&) }
  end

  def wait_until(seconds: 5)
    deadline = Process.clock_gettime(Process::CLOCK_MONOTONIC) + seconds
    sleep 0.01 until yield || Process.clock_gettime(Process::CLOCK_MONOTONIC) > deadline
  end

  def lock_waiters
    ActiveRecord::Base.connection.select_value(<<~SQL).to_i
      SELECT count(*) FROM pg_stat_activity WHERE datname = current_database() AND wait_event_type = 'Lock'
    SQL
  end
end
