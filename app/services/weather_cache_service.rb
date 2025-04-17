# frozen_string_literal: true

class WeatherCacheService
  # Cache expiry in minutes, configurable via WEATHER_CACHE_EXPIRY_MINUTES env variable (default: 30)
  EXPIRY = (ENV.fetch("WEATHER_CACHE_EXPIRY_MINUTES", 30).to_i).minutes

  # Returns the cache key for a given lat/lon
  def self.key_for(lat, lon)
    "weather:#{lat},#{lon}"
  end

  # Reads weather data from cache
  def self.read(lat, lon)
    Rails.cache.read(key_for(lat, lon))
  end

  # Writes weather data to cache
  def self.write(lat, lon, weather)
    if weather.is_a?(Hash)
      weather = weather.merge("cached_at" => Time.current.iso8601)
    end
    Rails.cache.write(key_for(lat, lon), weather, expires_in: EXPIRY)
  end

  # Optionally, expose delete/clear helpers if needed
  def self.delete(lat, lon)
    Rails.cache.delete(key_for(lat, lon))
  end
end
