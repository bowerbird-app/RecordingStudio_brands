# frozen_string_literal: true

class CreateRecordingStudioBrands < ActiveRecord::Migration[8.1]
  def change
    create_table :recording_studio_brands, id: :uuid, default: -> { "gen_random_uuid()" } do |t|
      t.string :name, null: false
      t.string :tagline
      t.text :description
      t.string :website_url
      t.string :email
      t.string :phone

      t.timestamps
    end
  end
end
