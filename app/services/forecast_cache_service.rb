# frozen_string_literal: true

class ForecastCacheService
  # Cache expiry in minutes, configurable via WEATHER_CACHE_EXPIRY_MINUTES env variable (default: 30)
  EXPIRY = ENV.fetch("WEATHER_CACHE_EXPIRY_MINUTES", 30).to_i * 60 # seconds

  # Use Rails' built-in delegation instead of manually defining class methods
  class << self
    delegate :key_for, :read, :write, :delete, to: :new
  end

  # Returns the cache key for a given lat/lon
  def key_for(lat, lon)
    "weather:#{lat},#{lon}"
  end

  # Reads weather data from cache
  def read(lat, lon)
    key = key_for(lat, lon)
    result = Rails.cache.read(key)
    Rails.logger.debug("CACHE READ: Key #{key}, Hit: #{!!result}") if Rails.env.development?
    result
  end

  # Writes weather data to cache
  def write(lat, lon, weather)
    key = key_for(lat, lon)
    if weather.is_a?(Hash)
      weather = weather.merge("cached_at" => Time.current.iso8601)
    end
    Rails.logger.debug("CACHE WRITE: Key #{key}, Type: #{weather.class.name}") if Rails.env.development?
    Rails.cache.write(key, weather, expires_in: EXPIRY)
  end

  # Delete cached forecast for a location
  def delete(lat, lon)
    Rails.cache.delete(key_for(lat, lon))
  end
end
