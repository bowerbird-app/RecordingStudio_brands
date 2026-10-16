# frozen_string_literal: true

require "recording_studio_admin"

module RecordingStudioBrands
  module Admin
    # Admin stores column/table titles as objects and stringifies them in the
    # view. This wrapper keeps i18n deferred to render time without rebuilding
    # the class-wide table on every query (which raced across locales).
    class LazyTitle
      def initialize(key)
        @key = key
      end

      def to_s
        RecordingStudio.t(@key)
      end
      alias to_str to_s

      def present?
        true
      end

      def blank?
        false
      end
    end

    class BrandsSection < RecordingStudioAdmin::Section
      key "brands"
      title { RecordingStudio.t("recording_studio.brands.admin.section_title") }
      subtitle { RecordingStudio.t("recording_studio.brands.admin.section_subtitle") }
      blast_radius :root

      link :catalogue,
           text: ->(_context) { RecordingStudio.t("recording_studio.brands.admin.catalogue_link") },
           url: ->(context) { context.admin_screen_path("recording_studio_brands") },
           style: :secondary
      link :new,
           text: ->(_context) { RecordingStudio.t("recording_studio.brands.admin.new_link") },
           url: ->(_context) { RecordingStudioBrands.admin_new_brand_path },
           style: :primary
    end

    class BrandsScreen < RecordingStudioAdmin::Screen
      key "recording_studio_brands"
      title { RecordingStudio.t("recording_studio.brands.admin.screen_title") }
      subtitle { RecordingStudio.t("recording_studio.brands.admin.screen_subtitle") }
      blast_radius :root

      button :new,
             text: ->(_context) { RecordingStudio.t("recording_studio.brands.actions.add_brand") },
             url: ->(_context) { RecordingStudioBrands.admin_new_brand_path },
             style: :primary

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

      # Built once from register! (and to_prepare). Column titles are LazyTitle
      # objects so copy still translates at render without per-query rebuilds.
      def self.define_catalogue_table!
        table do
          title LazyTitle.new("recording_studio.brands.admin.table_title")
          BrandsScreen.define_catalogue_columns(self)
          admin_action "brands.show", as: :open
          admin_action "brands.edit"
        end
      end

      def self.define_catalogue_columns(table)
        define_text_column(table, :name, "labels.name", :name)
        define_text_column(table, :slug, "labels.slug", :slug)
        define_active_column(table)
        define_text_column(table, :website_url, "labels.website", :website_url)
        table.column :updated_at, title: LazyTitle.new("recording_studio.brands.admin.updated_column")
      end

      def self.define_text_column(table, key, label_key, attribute)
        table.column key,
                     title: LazyTitle.new("recording_studio.brands.#{label_key}"),
                     sortable: false,
                     value: ->(recording, _context) { recording.recordable&.public_send(attribute) }
      end

      def self.define_active_column(table)
        table.column :active,
                     title: LazyTitle.new("recording_studio.brands.labels.active"),
                     sortable: false,
                     value: ->(recording, _context) { BrandsScreen.active_label(recording) },
                     display: :badge,
                     display_options: ->(recording, _context, _value) { BrandsScreen.active_badge_options(recording) }
      end

      def self.active_label(recording)
        key = recording.recordable&.active ? "active_yes" : "active_no"
        RecordingStudio.t("recording_studio.brands.labels.#{key}")
      end

      def self.active_badge_options(recording)
        {
          text: active_label(recording),
          style: recording.recordable&.active ? :success : :default,
          size: :sm
        }
      end
    end

    class BrandsResource < RecordingStudioAdmin::Resource
      key "brands"
      section "brands"
      title { RecordingStudio.t("recording_studio.brands.admin.resource_title") }
      blast_radius :root

      action :show,
             text: ->(_recording, _context) { RecordingStudio.t("recording_studio.brands.admin.show_action") },
             url: ->(recording, _context) { RecordingStudioBrands.admin_brand_path(recording) if recording },
             visible_if: ->(recording, _context) { recording.present? }

      action :edit,
             text: ->(_recording, _context) { RecordingStudio.t("recording_studio.brands.admin.edit_action") },
             required_role: :edit,
             url: lambda { |recording, _context|
               RecordingStudioBrands.edit_admin_brand_path(recording) if recording
             },
             visible_if: ->(recording, _context) { recording.present? }

      action :new,
             text: ->(_recording, _context) { RecordingStudio.t("recording_studio.brands.admin.new_action") },
             required_role: :edit,
             url: ->(_recording, _context) { RecordingStudioBrands.admin_new_brand_path }
    end

    def self.register!
      BrandsScreen.define_catalogue_table!
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
