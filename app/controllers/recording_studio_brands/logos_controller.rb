# frozen_string_literal: true

module RecordingStudioBrands
  class LogosController < ApplicationController
    before_action -> { load_brand(params[:brand_id], role: :edit) }

    def update
      file = params[:logo]
      if file.respond_to?(:original_filename) && save_logo(file)
        redirect_to brand_home_path(@brand_recording), notice: "Logo saved."
      else
        redirect_to brand_home_path(@brand_recording), alert: "The logo could not be saved. Choose an image file."
      end
    end

    private

    # Attachable returns nil instead of raising when it refuses the file, so
    # the blob uploaded here would otherwise stay in storage unattached.
    def save_logo(file)
      blob = ActiveStorage::Blob.create_and_upload!(io: file, filename: file.original_filename,
                                                    content_type: file.content_type)
      saved = record_logo(blob.signed_id)
      blob.purge unless saved
      saved
    end

    def record_logo(signed_blob_id)
      logo = Logo.recording_for(@brand_recording)
      return logo.replace_attachment_file(signed_blob_id:, actor: brands_actor) if logo

      @brand_recording.record_attachment_upload(signed_blob_id:, name: Logo::NAME, actor: brands_actor)
    end
  end
end
