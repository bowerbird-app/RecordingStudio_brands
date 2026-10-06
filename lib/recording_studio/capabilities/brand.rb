# frozen_string_literal: true

module RecordingStudio
  module Capabilities
    module Brand
      # Parses allows before core stores it, so a bad mount fails when the host
      # model loads instead of on the first write.
      def self.to(allows:)
        RecordingStudioBrands::Mount.kind_for(allows)
        RecordingStudio::Capabilities.include_for(:brand, allows:)
      end

      module RecordingMethods
        extend ActiveSupport::Concern

        included do
          before_create :recording_studio_brands_refuse_second_brand,
                        if: -> { recordable_type == RecordingStudioBrands::BRAND_TYPE }
        end

        private

        # Runs on insert only, so revise and revert never reach it. Inside
        # record! the transaction already holds this parent lock. A direct
        # Recording.create! takes it here, so concurrent creates serialize.
        def recording_studio_brands_refuse_second_brand
          parent = self.class.unscoped.lock.find(parent_recording_id)
          return unless RecordingStudioBrands::Mount.for(parent)&.full?

          raise RecordingStudioBrands::BrandLimitReached, parent
        end
      end
    end
  end
end

RecordingStudio.register_capability(
  :brand,
  recording_methods: RecordingStudio::Capabilities::Brand::RecordingMethods,
  source: "recording_studio_brands",
  child_recordables: [RecordingStudioBrands::BRAND_TYPE]
)
