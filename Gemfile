source "https://rubygems.org"

# --- Core Framework & Database ---
gem "rails", "~> 8.0.2"
gem "pg", "~> 1.1"           # PostgreSQL for Active Record

gem "solid_cache"            # Rails.cache adapter
 gem "solid_queue"            # Active Job adapter

gem "propshaft"              # Modern asset pipeline

gem "bootsnap", require: false # Caching for faster boot

gem "puma", ">= 5.0"          # Web server

# --- Frontend & Styling ---
gem "tailwindcss-rails"        # Tailwind CSS

gem "importmap-rails"         # ESM import maps

gem "hotwire-rails"             # Hotwire Turbo

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
end  # (Only need one group :development, :test for these gems)

group :test do
  gem "capybara"
  gem "selenium-webdriver"
  gem "simplecov", require: false
  gem "vcr"
  gem "webmock"
end

group :development do
  # Use console on exceptions pages [https://github.com/rails/web-console]
  gem "web-console"
end
