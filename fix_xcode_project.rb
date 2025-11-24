#!/usr/bin/env ruby

require 'xcodeproj'

# Open the project
project = Xcodeproj::Project.open('Tunes4S.xcodeproj')

# Find the main target
target = project.targets.find { |t| t.name == 'Tunes4S' }
puts "Found target: #{target.name}"

# Structure to organize files
files_to_add = {
  'Models' => [
    'Tunes4S/Models/Song.swift',
    'Tunes4S/Models/SpectrumViewModel.swift',
    'Tunes4S/Models/EqualizerPreset.swift',
    'Tunes4S/Models/PlayerViewModel.swift',
    'Tunes4S/Models/EqualizerViewModel.swift'
  ],
  'Extensions' => [
    'Tunes4S/Extensions/Color+Hex.swift'
  ],
  'Components' => [
    'Tunes4S/Components.swift'
  ],
  'Views' => {
    'Components' => [
      'Tunes4S/Views/Components/WinampBackground.swift',
      'Tunes4S/Views/Components/WinampButton.swift',
      'Tunes4S/Views/Components/WinampToggleButton.swift',
      'Tunes4S/Views/Components/WinampTimeDisplay.swift',
      'Tunes4S/Views/Components/ScrollingText.swift',
      'Tunes4S/Views/Components/WinampLEDText.swift',
      'Tunes4S/Views/Components/WinampVolumeControl.swift'
    ],
    'Sections' => [
      'Tunes4S/Views/Sections/WinampTitleBar.swift'
    ]
  }
}

# Add files with proper organization
files_to_add.each do |group_name, files|
  puts "Processing group: #{group_name}"

  if files.is_a?(Hash)
    # Handle nested structure like Views/Components
    files.each do |subgroup_name, subgroup_files|
      puts "Processing subgroup: #{subgroup_name}"
      subgroup_files.each do |file_path|
        if File.exist?(file_path)
          puts "Adding file: #{file_path}"
          file_ref = project.main_group.find_file_by_path(file_path) ||
                      project.main_group.new_reference(file_path)
          target.add_file_references([file_ref])
        else
          puts "Warning: File not found: #{file_path}"
        end
      end
    end
  else
    # Handle flat structure like Models
    files.each do |file_path|
      if File.exist?(file_path)
        puts "Adding file: #{file_path}"
        file_ref = project.main_group.find_file_by_path(file_path) ||
                    project.main_group.new_reference(file_path)
        target.add_file_references([file_ref])
      else
        puts "Warning: File not found: #{file_path}"
      end
    end
  end
end

# Save the project
project.save
puts "✅ Xcode project updated successfully!"
puts "The missing files have been added to the project."
