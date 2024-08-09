# The script takes a safe-deployments v2 format as an input
# and outputs the change where the "networkAddresses" is an array
# instead of a mix of single and array values.
#
# To run the patch for every json file inside an "assets" directory:
#       find Packages/Ethereum/Sources/SafeDeployments/assets -type f -name "*.json" -print0 | xargs -0 -I {} ruby bin/patch_safe_deployments.rb "{}"
require 'json'

# Check if a filename was provided as a command-line argument
if ARGV.length != 1
  puts "Usage: ruby patch_safe_deployments.rb <file_name.json>"
  exit
end

# Get the filename from the command-line argument
file_path = ARGV[0]

begin
  # Read the JSON file
  file = File.read(file_path)

  # Parse the JSON data
  data = JSON.parse(file)

  # Skip the file if 'networkAddresses' key does not exist
  unless data.key?('networkAddresses')
    puts "Skipping file (no 'networkAddresses' key): #{file_path}"
    exit
  end

  # Modify the networkAddresses values to always be arrays
  data['networkAddresses'].each do |key, value|
    # If the value is not already an array, convert it to an array
    data['networkAddresses'][key] = Array(value) unless value.is_a?(Array)
  end

  # Write the updated JSON back to the file
  File.open(file_path, 'w') do |f|
    f.write(JSON.pretty_generate(data))
  end

  puts "The networkAddresses values have been updated successfully in #{file_path}."

rescue Errno::ENOENT
  puts "Error: File not found - #{file_path}"
rescue JSON::ParserError
  puts "Error: File is not a valid JSON - #{file_path}"
end
