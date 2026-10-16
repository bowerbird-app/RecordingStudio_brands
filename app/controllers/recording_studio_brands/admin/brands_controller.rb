# frozen_string_literal: true

module RecordingStudioBrands
  module Admin
    class BrandsController < ApplicationController # rubocop:disable Metrics/ClassLength
      include RecordingStudioAdmin::AdminActionAuditing

      before_action :authenticate_brands_actor!
      before_action :authorize_brand!

      rescue_from RecordingStudioAdmin::AuthorizationFailed, RecordingStudioAdmin::DefinitionNotFound do
        head :forbidden
      end

      def new
        assign_form(Brand.new(active: true))
      end

      def create
        parent = brand_parent
        return render_missing_root if parent.blank?

        recording = create_brand_recording!(parent)
        redirect_to admin_brand_path(recording), notice: brand_saved_notice
      rescue BrandLimitReached
        render_brand_limit(parent)
      rescue ActiveRecord::RecordInvalid => e
        render_invalid(:new, e)
      end

      def show
        assign_shown_brand
      end

      def edit
        assign_shown_brand
        assign_form(@brand)
      end

      def update
        redirect_to admin_brand_path(revise_brand!), notice: brand_saved_notice
      rescue ActiveRecord::RecordInvalid => e
        assign_shown_brand
        render_invalid(:edit, e)
      end

      private

      def create_brand_recording!(parent)
        write_brand!(:new, parent, audit_action: :create) do
          parent.record(Brand, parent_recording: parent, actor: brands_actor) do |brand|
            assign_brand_attributes(brand, parent)
          end
        end
      end

      def render_brand_limit(parent)
        flash.now[:alert] = t(
          "recording_studio.brands.flashes.brand_limit",
          type: parent.type_label.downcase,
          # rubocop:disable-next Style/FormatStringToken -- I18n interpolation
          default: "This %{type} already has a brand."
        )
        assign_form_from_params
        render :new, status: :unprocessable_content
      end

      def authorize_brand!
        RecordingStudioAdmin.authorize_resource!(
          key: "brands",
          action: brand_resource_action,
          context: recording_studio_admin_context,
          record: brand_authorization_record,
          audit: true,
          audit_action: action_name
        )
      end

      def brand_resource_action
        case action_name
        when "create" then :new
        when "update" then :edit
        else action_name.to_sym
        end
      end

      def brand_authorization_record
        return if %w[new create].include?(action_name)

        brand_recording
      end

      def write_brand!(action, record, audit_action:)
        result = nil
        perform_recording_studio_admin_action!("brands", action, record, audit_action: audit_action) do
          result = yield
          true
        end
        result
      end

      def recording_studio_admin_context
        @recording_studio_admin_context ||= RecordingStudioAdmin::Context.new(
          params: params.to_unsafe_h,
          current_actor: brands_actor,
          controller: self,
          routes: self,
          view_context: view_context
        )
      end

      def brand_recording
        @brand_recording ||= brand_children.find(params[:id])
      end

      def brand_children
        root = brand_parent
        relation = RecordingStudio::Recording.where(
          recordable_type: BRAND_TYPE,
          parent_recording_id: root&.id
        )
        return relation.none if root.blank?
        return relation unless RecordingStudio::Recording.column_names.include?("trashed_at")

        relation.where(trashed_at: nil)
      end

      def brand_parent
        root = current_brand_root
        return if root.blank?
        return unless Mount.for(root)

        root
      end

      def current_brand_root
        return unless respond_to?(:current_root_recording, true)

        send(:current_root_recording)
      end

      def revise_brand!
        write_brand!(:edit, brand_recording, audit_action: :update) do
          brand_recording.root_recording.revise(brand_recording, actor: brands_actor) do |brand|
            assign_brand_attributes(brand, brand_recording.parent_recording)
          end
        end
      end

      def assign_shown_brand
        @brand = brand_recording.recordable
        @brand_recording = brand_recording
        @logo = Logo.recording_for(brand_recording)
      end

      def assign_brand_attributes(brand, parent)
        brand.parent_recording_id_for_slug = parent.id
        brand.slug_uniqueness_except_recording_id = @brand_recording&.id
        brand.assign_attributes(brand_attributes)
      end

      def render_missing_root
        flash.now[:alert] = t(
          "recording_studio.brands.flashes.admin_root_missing",
          default: "Pick a root that holds brands, then try again."
        )
        assign_form_from_params(validate: false)
        render :new, status: :unprocessable_content
      end

      def render_invalid(template, error)
        flash.now[:alert] = error.record.errors.full_messages.to_sentence.presence ||
                            t("recording_studio.brands.flashes.brand_invalid",
                              default: "Check the brand and try again.")
        assign_form_from_params
        render template, status: :unprocessable_content
      end

      def assign_form_from_params(validate: true)
        brand = Brand.new(brand_attributes)
        brand.parent_recording_id_for_slug = brand_parent&.id
        brand.valid? if validate && brand.parent_recording_id_for_slug.present?
        assign_form(brand)
      end

      def assign_form(brand)
        @brand = brand
      end

      def brand_attributes
        permitted = brand_params.to_h
        permitted[:active] = ActiveModel::Type::Boolean.new.cast(permitted[:active]) if permitted.key?(:active)
        permitted
      end

      def brand_params
        params.fetch(:brand, ActionController::Parameters.new).permit(
          *(Brand::FIELDS + [:active])
        )
      end

      def brand_saved_notice
        t("recording_studio.brands.flashes.brand_saved", default: "Brand saved.")
      end
    end
  end
end
