# This file should ensure the existence of records required to run the application in every environment (production,
# development, test). The code here should be idempotent so that it can be executed at any point in every environment.
# The data can then be loaded with the bin/rails db:seed command (or created alongside the database with db:setup).

find_or_record_child = lambda do |recordable, root_recording, parent_recording|
  RecordingStudio::Recording.find_by(
    root_recording: root_recording,
    parent_recording: parent_recording,
    recordable: recordable,
    trashed_at: nil
  ) || RecordingStudio.record!(
    action: "created",
    recordable: recordable,
    root_recording: root_recording,
    parent_recording: parent_recording
  ).recording
end

ensure_owner = lambda do |recording, actor|
  next if RecordingStudioAccessible.authorized?(actor: actor, recording: recording, role: :edit)

  access = RecordingStudioAccessible.bootstrap_owner_access!(recording: recording, actor: actor)
  raise access.error if access.failure?
end

ensure_brand = lambda do |parent, attributes|
  existing = RecordingStudio::Recording
             .where(parent_recording: parent, recordable_type: RecordingStudioBrands::BRAND_TYPE, trashed_at: nil)
             .includes(:recordable)
             .detect { |recording| recording.recordable.name == attributes[:name] }
  next existing if existing

  parent.record(RecordingStudioBrands::Brand, parent_recording: parent, actor: Current.actor) do |brand|
    brand.assign_attributes(attributes)
  end
end

# Create the admin user
user = User.find_or_create_by!(email: "admin@admin.com") do |u|
  u.password = "Password"
  u.password_confirmation = "Password"
end

# Create the workspace recordables
workspace = Workspace.find_or_create_by!(name: "Studio Workspace")
accessible_workspace = Workspace.find_or_create_by!(name: "Client Workspace")
private_workspace = Workspace.find_or_create_by!(name: "Private Workspace")
folder = Folder.find_or_create_by!(name: "Product Docs")
page = Page.find_or_create_by!(title: "Getting Started")

previous_actor = Current.actor
Current.actor = user

begin
  # Create the root recording
  root_recording = RecordingStudio.root_recording_for(workspace)
  accessible_root_recording = RecordingStudio.root_recording_for(accessible_workspace)
  private_root_recording = RecordingStudio.root_recording_for(private_workspace)

  folder_recording = find_or_record_child.call(folder, root_recording, root_recording)
  find_or_record_child.call(page, root_recording, folder_recording)

  ensure_owner.call(root_recording, user)
  ensure_owner.call(accessible_root_recording, user)

  ensure_brand.call(root_recording, {
    name: "Taylor Swift",
    tagline: "The Eras Tour",
    description: "Singer and songwriter.",
    website_url: "https://www.taylorswift.com",
    email: "hello@taylorswift.com",
    phone: "+1 615 555 0100"
  })
  ensure_brand.call(folder_recording, {
    name: "Nike",
    tagline: "Just Do It",
    website_url: "https://www.nike.com"
  })
  ensure_brand.call(folder_recording, {
    name: "Dove",
    tagline: "Real beauty",
    website_url: "https://www.dove.com"
  })
  ensure_brand.call(folder_recording, {
    name: "Acme Coffee",
    tagline: "Roasted for the launch",
    description: "The coffee brand for the Acme launch.",
    website_url: "https://acme.example/coffee",
    email: "hello@acme.example"
  })
ensure
  Current.actor = previous_actor
end

puts "Seeded: admin@admin.com / Password"
puts "Seeded: Workspace '#{workspace.name}' with Taylor Swift"
puts "Seeded: Workspace '#{accessible_workspace.name}' with no brand yet"
puts "Seeded: Workspace '#{private_workspace.name}' with no access for the admin"
puts "Seeded: Folder '#{folder.name}' with Nike, Dove, and Acme Coffee"
puts "Seeded: Page '#{page.title}'"
