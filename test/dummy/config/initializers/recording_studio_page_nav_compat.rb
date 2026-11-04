# frozen_string_literal: true

# Admin 2.3.2 screens still call recording_studio_page_nav, which core 6 removed.
# Keep the Admin pin; restore the old helper on LayoutHelper for this dummy host only.
Rails.application.config.to_prepare do
  next if RecordingStudio::LayoutHelper.method_defined?(:recording_studio_page_nav)

  RecordingStudio::LayoutHelper.class_eval do
    def recording_studio_page_nav(title: nil, **options)
      content_for :title, title if title.present?
      options.each do |key, value|
        content_for(key, value) if value.present?
      end
      nil
    end
  end
end
