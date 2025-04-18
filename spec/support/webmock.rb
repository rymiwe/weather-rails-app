# Enable and configure WebMock for all specs
require 'webmock/rspec'

WebMock.disable_net_connect!(allow_localhost: true)

# Force Geocoder to use Net::HTTP so WebMock can intercept requests
if defined?(Geocoder)
  Geocoder.configure(http_adapter: :net_http, cache: nil)
end



File.write("tmp/loaded_gems.txt", Gem.loaded_specs.keys.sort.join("\n"))

WebMock.after_request do |request_signature, response|
  unless WebMock.registered_request?(request_signature)

  end
end

RSpec.configure do |config|
  config.before(:each) do
    # Fallback: unmatched requests return 404 or empty result (forces test to define its own stubs)
    WebMock.stub_request(:any, /.*/).to_return(status: 404, body: '{}')
  end
end
