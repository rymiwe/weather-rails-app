# frozen_string_literal: true

class WeatherCacheService
  EXPIRY = 30.minutes

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
    Rails.cache.write(key_for(lat, lon), weather, expires_in: EXPIRY)
  end

  # Optionally, expose delete/clear helpers if needed
  def self.delete(lat, lon)
    Rails.cache.delete(key_for(lat, lon))
  end
end
