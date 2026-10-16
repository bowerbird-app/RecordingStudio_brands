# frozen_string_literal: true

require "recording_studio_admin"

module RecordingStudioBrands
  module Admin
    class BrandsSection < RecordingStudioAdmin::Section
      key "brands"
      title RecordingStudio.t("recording_studio.brands.admin.section_title")
      subtitle RecordingStudio.t("recording_studio.brands.admin.section_subtitle")
      blast_radius :root

      link :catalogue,
           text: RecordingStudio.t("recording_studio.brands.admin.catalogue_link"),
           url: ->(context) { context.admin_screen_path("recording_studio_brands") },
           style: :secondary
      link :new,
           text: RecordingStudio.t("recording_studio.brands.admin.new_link"),
           url: ->(_context) { RecordingStudioBrands.admin_new_brand_path },
           style: :primary
    end

    class BrandsScreen < RecordingStudioAdmin::Screen
      key "recording_studio_brands"
      title RecordingStudio.t("recording_studio.brands.admin.screen_title")
      subtitle RecordingStudio.t("recording_studio.brands.admin.screen_subtitle")
      blast_radius :root
      query do |context|
        root = context.root_recording
        next RecordingStudio::Recording.none if root.blank?
        next RecordingStudio::Recording.none unless Mount.for(root)

        relation = RecordingStudio::Recording.where(
          recordable_type: BRAND_TYPE,
          parent_recording_id: root.id
        )
        relation = relation.where(trashed_at: nil) if RecordingStudio::Recording.column_names.include?("trashed_at")
        relation.includes(:recordable).order(updated_at: :desc)
      end

      table do
        title RecordingStudio.t("recording_studio.brands.admin.table_title")
        column :name,
               title: RecordingStudio.t("recording_studio.brands.labels.name"),
               sortable: false,
               value: ->(recording, _context) { recording.recordable&.name }
        column :slug,
               title: RecordingStudio.t("recording_studio.brands.labels.slug"),
               sortable: false,
               value: ->(recording, _context) { recording.recordable&.slug }
        column :active,
               title: RecordingStudio.t("recording_studio.brands.labels.active"),
               sortable: false,
               value: lambda { |recording, _context|
                 key = recording.recordable&.active ? "active_yes" : "active_no"
                 RecordingStudio.t("recording_studio.brands.labels.#{key}")
               }
        column :website_url,
               title: RecordingStudio.t("recording_studio.brands.labels.website"),
               sortable: false,
               value: ->(recording, _context) { recording.recordable&.website_url }
        column :updated_at, title: RecordingStudio.t("recording_studio.brands.admin.updated_column")
        admin_action "brands.show", as: :open
        admin_action "brands.edit"
      end
    end

    class BrandsResource < RecordingStudioAdmin::Resource
      key "brands"
      section "brands"
      title RecordingStudio.t("recording_studio.brands.admin.resource_title")
      blast_radius :root

      action :show,
             text: RecordingStudio.t("recording_studio.brands.admin.show_action"),
             url: ->(recording, _context) { RecordingStudioBrands.admin_brand_path(recording) if recording },
             visible_if: ->(recording, _context) { recording.present? }

      action :edit,
             text: RecordingStudio.t("recording_studio.brands.admin.edit_action"),
             required_role: :edit,
             url: lambda { |recording, _context|
               RecordingStudioBrands.edit_admin_brand_path(recording) if recording
             },
             visible_if: ->(recording, _context) { recording.present? }

      action :new,
             text: RecordingStudio.t("recording_studio.brands.admin.new_action"),
             required_role: :edit,
             url: ->(_recording, _context) { RecordingStudioBrands.admin_new_brand_path }
    end

    def self.register!
      RecordingStudioAdmin.register_section(BrandsSection)
      RecordingStudioAdmin.register_screen(BrandsScreen)
      RecordingStudioAdmin.register_resource(BrandsResource)
    end
  end

  def self.admin_brands_path
    engine_admin_path(:admin_brands_path)
  end

  def self.admin_new_brand_path
    engine_admin_path(:new_admin_brand_path)
  end

  def self.admin_brand_path(recording)
    engine_admin_path(:admin_brand_path, recording)
  end

  def self.edit_admin_brand_path(recording)
    engine_admin_path(:edit_admin_brand_path, recording)
  end

  def self.engine_admin_path(helper, *)
    Engine.routes.url_helpers.public_send(helper, *, script_name: configuration.mount_path)
  end
  private_class_method :engine_admin_path
end
