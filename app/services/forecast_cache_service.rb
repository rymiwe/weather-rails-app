# frozen_string_literal: true

class ForecastCacheService
  EXPIRY = 30.minutes

  # Returns the cache key for a given lat/lon
  def self.key_for(lat, lon)
    "forecast:#{lat},#{lon}"
  end

  # Reads a forecast from cache
  def self.read(lat, lon)
    Rails.cache.read(key_for(lat, lon))
  end

  # Writes a forecast to cache
  def self.write(lat, lon, forecast)
    Rails.cache.write(key_for(lat, lon), forecast, expires_in: EXPIRY)
  end

  # Optionally, expose delete/clear helpers if needed
  def self.delete(lat, lon)
    Rails.cache.delete(key_for(lat, lon))
  end
end
