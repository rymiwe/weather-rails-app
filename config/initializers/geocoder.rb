# Geocoder configuration for Rails 8
# Enables built-in caching using Rails.cache (default store)
# This is the recommended approach for most Rails apps.

Geocoder.configure(
  cache: Rails.cache,
  cache_prefix: "geocoder:",
  country_bias: "US" # Prefer US results for ambiguous queries
)
