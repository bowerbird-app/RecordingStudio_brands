# frozen_string_literal: true

module RecordingStudioBrands
  module Api
    class Index < RecordingStudioApi::Services::ResourceOperations::Index
      private

      def filtered_recordings
        identity_recording = identity_brand_recording
        return super if identity_recording.nil? && !identity_lookup_requested?

        relation = scoped_recordings.where(recordable_type: recordable_type)
        return relation.none if identity_recording.nil?

        relation.where(id: identity_recording.id)
      end

      def identity_lookup_requested?
        identity_lookup_args.values.any?(&:present?)
      end

      def identity_brand_recording
        args = identity_lookup_args
        return if args.values.all?(&:blank?)

        Identity.find_brand_recording(**args, parent_recording: identity_parent_recording)
      end

      def identity_lookup_args
        filters = identity_filters
        {
          slug: filters["slug"].presence || params[:slug].presence,
          name: filters["name"].presence || params[:name].presence,
          website_url: filters["website_url"].presence || params[:website_url].presence
        }
      end

      def identity_filters
        raw = params[:filter]
        return {} if raw.blank?

        if raw.respond_to?(:to_unsafe_h)
          raw.to_unsafe_h.stringify_keys
        elsif raw.respond_to?(:to_h)
          raw.to_h.stringify_keys
        else
          {}
        end
      end

      def identity_parent_recording
        parent_id = params[:parent_id].presence || identity_filters["parent_id"].presence
        return if parent_id.blank?

        scoped_recordings.find_by(id: parent_id)
      end
    end
  end
end
