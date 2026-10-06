# frozen_string_literal: true

module RecordingStudioBrands
  class BrandsController < ApplicationController
    before_action -> { load_parent(role: :view) }, only: :index
    before_action -> { load_parent(role: :edit) }, only: %i[new create]
    before_action -> { load_brand(params[:id], role: :view) }, only: :show
    before_action -> { load_brand(params[:id], role: :edit) }, only: %i[edit update]

    def index
      case @mount
      in Mount::One then render_one
      in Mount::Many then render_list(:many)
      end
    end

    def new
      return redirect_to(recording_brands_path(@parent), alert: limit_message) if @mount.full?

      @brand = Brand.new
    end

    def create
      brand_recording = @parent.record(Brand, parent_recording: @parent, actor: brands_actor) do |brand|
        brand.assign_attributes(brand_params)
      end
      redirect_to brand_home_path(brand_recording), notice: "Brand saved."
    rescue BrandLimitReached
      redirect_to recording_brands_path(@parent), alert: limit_message
    rescue ActiveRecord::RecordInvalid => e
      render_invalid(e, :new)
    end

    def show
      @logo = Logo.recording_for(@brand_recording)
    end

    def edit
      @brand = @brand_recording.recordable
    end

    def update
      @parent.revise(@brand_recording, actor: brands_actor) { |brand| brand.assign_attributes(brand_params) }
      redirect_to brand_home_path(@brand_recording), notice: "Brand saved."
    rescue ActiveRecord::RecordInvalid => e
      render_invalid(e, :edit)
    end

    private

    def load_parent(role:)
      @parent = RecordingStudio::Recording.find(params[:recording_id])
      @mount = Mount.for(@parent) || raise(ActiveRecord::RecordNotFound)
      authorize_recording!(@parent, role:)
    end

    def render_one
      @brand_recording = @mount.brand_recording
      @logo = Logo.recording_for(@brand_recording) if @brand_recording
      render :one
    rescue MountConflict
      render_list(:conflict)
    end

    def render_list(template)
      @brand_recordings = @mount.brand_recordings.includes(:recordable).to_a
      render template
    end

    def render_invalid(error, template)
      raise error unless error.record.is_a?(Brand)

      @brand = error.record
      render template, status: :unprocessable_content
    end

    def brand_params
      params.expect(brand: Brand::FIELDS)
    end

    def limit_message
      "This #{@parent.type_label.downcase} already has a brand."
    end
  end
end
