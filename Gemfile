source "https://rubygems.org"

# --- Core Framework ---
gem "rails", "~> 8.0.2"         # Rails framework
gem "redis", "~> 5.0"          # Redis for caching
gem "puma", ">= 5.0"          # Web server
gem "bootsnap", require: false # Speed up boot time

# --- Frontend & UI ---
gem "propshaft"               # Modern asset pipeline
gem "tailwindcss-rails"       # Tailwind CSS framework
gem "importmap-rails"         # JS imports without bundling
gem "hotwire-rails"           # Modern, HTML-driven frontend

# --- API & Services ---
gem "geocoder", ">= 1.6"      # Geocoding service integration
gem "faraday", "~> 2.0"       # HTTP client for API requests

# --- Development & Test Groups ---
group :development, :test do
  gem "rspec-rails"            # Testing framework
  gem "debug", platforms: %i[ mri windows ], require: "debug/prelude" # Debugging
  gem "brakeman", require: false # Security analysis
  gem "rubocop-rails-omakase", require: false # Code style & quality
end

group :test do
  gem "simplecov", require: false # Test coverage reports
  gem "vcr"                      # Record HTTP interactions for tests
  gem "webmock"                  # Mock HTTP requests in tests
  gem "capybara"                 # Browser testing framework
  gem "selenium-webdriver"       # WebDriver for browser automation
end

group :development do
  gem "web-console"             # Console in browser for debugging
  gem "tidewave"                # For MCP context
end
