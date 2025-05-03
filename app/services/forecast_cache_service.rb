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
    if result
      # Always log cache hits in all environments, not just development
      Rails.logger.info("CACHE HIT: Key #{key}")
    else
      Rails.logger.debug("CACHE MISS: Key #{key}")
    end
    result
  end

  # Writes weather data to cache
  def write(lat, lon, weather)
    key = key_for(lat, lon)
    
    # Add timestamp to forecast object's raw_data
    if weather.is_a?(Forecast) && weather.raw_data.is_a?(Hash)
      weather.raw_data["cached_at"] = Time.current.iso8601
    elsif weather.is_a?(Hash)
      weather = weather.merge("cached_at" => Time.current.iso8601)
    end
    
    # Log in all environments, not just development
    Rails.logger.info("CACHE WRITE: Key #{key}, Type: #{weather.class.name}")
    
    # Cache the data
    Rails.cache.write(key, weather, expires_in: EXPIRY)
  end

  # Delete cached forecast for a location
  def delete(lat, lon)
    Rails.cache.delete(key_for(lat, lon))
  end
end
