# Enable and configure WebMock for all specs
require 'webmock/rspec'

WebMock.disable_net_connect!(allow_localhost: true)

# Force Geocoder to use Net::HTTP so WebMock can intercept requests
if defined?(Geocoder)
  Geocoder.configure(http_adapter: :net_http, cache: nil)
end

puts "WebMock support loaded"
puts "[DEBUG] Loaded gems: #{Gem.loaded_specs.keys.sort.join(', ')}"
File.write("tmp/loaded_gems.txt", Gem.loaded_specs.keys.sort.join("\n"))

WebMock.after_request do |request_signature, response|
  unless WebMock.registered_request?(request_signature)
    puts "[WebMock] Unmatched request: #{request_signature.method} #{request_signature.uri}"
  end
end

RSpec.configure do |config|
  config.before(:each) do
    # Universal WebMock stubs for geocoding queries used in all specs
    # GLOBAL CATCH-ALL STUB (for debugging: catches any HTTP request)
    WebMock.stub_request(:any, /.*/).
      to_return(status: 200, body: '{"features": [{"geometry": {"coordinates": [-74.0060, 40.7128]}, "properties": {"city": "New York", "state": "NY", "country": "US"}}]}')
    # Universal Pirate Weather API stub
    WebMock.stub_request(:get, /pirate-weather-api|pirateweather/).
      to_return(status: 200, body: '{"currently":{"summary":"Clear","temperature":70},"daily":{"summary":"Sunny","icon":"clear-day","data":[{"icon":"clear-day","temperatureHigh":80,"temperatureLow":60}]}}')
  end
end
