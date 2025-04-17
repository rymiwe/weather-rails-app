source "https://rubygems.org"

# --- Core Framework & Database ---
gem "rails", "~> 8.0.2"
gem "pg", "~> 1.1"           # PostgreSQL for Active Record

gem "propshaft"              # Modern asset pipeline

gem "solid_cache"            # Rails.cache adapter
 gem "solid_queue"            # Active Job adapter

gem "bootsnap", require: false # Caching for faster boot

gem "puma", ">= 5.0"          # Web server

gem "kamal", require: false    # Docker deployment

gem "thruster", require: false # HTTP asset caching/compression

gem "tzinfo-data", platforms: %i[ windows jruby ] # Windows timezones

# --- Frontend & Styling ---
gem "tailwindcss-rails"        # Tailwind CSS

gem "importmap-rails"         # ESM import maps

gem "turbo-rails"             # Hotwire Turbo

gem "stimulus-rails"          # Hotwire Stimulus

# --- Geocoding ---
gem "geocoder", ">= 1.6"

# --- HTTP/External ---
gem "faraday", "~> 2.0"         # HTTP requests (API, CDN validation)

# --- Development & Test ---
group :development, :test do
  gem "rspec-rails"                # RSpec for testing
  gem "debug", platforms: %i[ mri windows ], require: "debug/prelude"
  gem "brakeman", require: false   # Security analysis
  gem "rubocop-rails-omakase", require: false # Ruby style
end

group :development do
  gem "web-console"                # Rails console in browser
end

group :test do
  gem "capybara"                   # System testing
  gem "selenium-webdriver"         # Browser driver for Capybara
  gem "webmock"                    # HTTP stubbing
  gem "vcr"                        # HTTP recording
end

# --- Optional ---
# gem "bcrypt", "~> 3.1.7"         # For has_secure_password
group :development, :test do
  # See https://guides.rubyonrails.org/debugging_rails_applications.html#debugging-with-the-debug-gem
  gem "debug", platforms: %i[ mri windows ], require: "debug/prelude"

  # Static analysis for security vulnerabilities [https://brakemanscanner.org/]
  gem "brakeman", require: false

  # Omakase Ruby styling [https://github.com/rails/rubocop-rails-omakase/]
  gem "rubocop-rails-omakase", require: false
end

group :development do
  # Use console on exceptions pages [https://github.com/rails/web-console]
  gem "web-console"
end

group :test do
  gem "capybara"                   # System testing
  gem "selenium-webdriver"         # Browser driver for Capybara
  gem "webmock"                    # HTTP stubbing
  gem "vcr"                        # HTTP recording
end
