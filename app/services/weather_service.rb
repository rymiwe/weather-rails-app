# frozen_string_literal: true

class WeatherService
  # Returns [forecast, from_cache, error_message]
  def self.fetch(query, refresh: false)
    return [ nil, false, "Please enter a location." ] if query.blank?

    geo_data = GeocodingService.lookup(query)
    unless geo_data
      return [ nil, false, "Could not geocode query." ]
    end
    lat = geo_data[:lat]
    lon = geo_data[:lon]
    location_name = geo_data[:location_name]

    forecast = WeatherCacheService.read(lat, lon)
    unless forecast.nil? || refresh
      return [ forecast, true, nil, location_name ]
    end

    begin
      client = PirateWeatherClient.new
      forecast = client.fetch_forecast(lat, lon)
      WeatherCacheService.write(lat, lon, forecast)
      [ forecast, false, nil, location_name ]
    rescue => e
      [ nil, false, "Error fetching weather data.", location_name ]
    end
  end
end
