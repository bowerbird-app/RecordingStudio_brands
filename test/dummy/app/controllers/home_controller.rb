class HomeController < ApplicationController
  def index
    parent_types = RecordingStudio.capability_parent_types_for(RecordingStudioBrands::BRAND_TYPE)

    @brand_parents = RecordingStudio::Recording.where(recordable_type: parent_types, trashed_at: nil)
                                               .includes(:recordable)
                                               .order(:created_at, :id)
                                               .select do |recording|
      RecordingStudioAccessible.authorized?(actor: current_user, recording:, role: :view)
    end
  end
end
