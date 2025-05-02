# frozen_string_literal: true

class ForecastCacheService
  # Cache expiry in minutes, configurable via WEATHER_CACHE_EXPIRY_MINUTES env variable (default: 30)
  # Explicitly convert to seconds to avoid ActiveSupport dependency
  EXPIRY = ENV.fetch("WEATHER_CACHE_EXPIRY_MINUTES", 30).to_i * 60 # seconds

  class << self
    # Class methods that delegate to instance methods
    def key_for(lat, lon)
      new.key_for(lat, lon)
    end

    def read(lat, lon)
      new.read(lat, lon)
    end

    def write(lat, lon, weather)
      new.write(lat, lon, weather)
    end

    def delete(lat, lon)
      new.delete(lat, lon)
    end
  end

  # Returns the cache key for a given lat/lon
  def key_for(lat, lon)
    "weather:#{lat},#{lon}"
  end

  # Reads weather data from cache
  def read(lat, lon)
    Rails.cache.read(key_for(lat, lon))
  end

  # Writes weather data to cache
  def write(lat, lon, weather)
    if weather.is_a?(Hash)
      weather = weather.merge("cached_at" => Time.current.iso8601)
    end
    Rails.cache.write(key_for(lat, lon), weather, expires_in: EXPIRY)
  end

  # Optionally, expose delete/clear helpers if needed
  def delete(lat, lon)
    Rails.cache.delete(key_for(lat, lon))
  end
end
