# frozen_string_literal: true

class ForecastService
  # Returns a ForecastResult object
  # Accepts a geocoder: argument for dependency injection.
  # Accepts a weather_client: argument for testability.
  # This enables robust, isolated tests by allowing explicit Geocoder and weather client mocking in specs.
  def self.fetch(query, refresh: false, geocoder: Geocoder, weather_client: PirateWeatherClient)
    return ForecastResult.new(error_message: "Please enter an query.") if query.blank?

    geo_data = GeocodingService.lookup(query, geocoder: geocoder)
    unless geo_data
      return ForecastResult.new(error_message: "Could not geocode query.")
    end
    lat = geo_data[:lat]
    lon = geo_data[:lon]
    location_name = geo_data[:location_name]
    units = geo_data[:units] || "us"

    cached = ForecastCacheService.read(lat, lon)
    if cached.is_a?(Forecast) && !refresh
      return ForecastResult.new(
        forecast: cached,
        from_cache: true,
        location_name: location_name,
        units: units
      )
    end

    begin
      client = weather_client.is_a?(Class) ? weather_client.new : weather_client
      raw = client.fetch_forecast(lat, lon, units: units)
      if raw.nil?
        return ForecastResult.new(
          error_message: "Could not retrieve forecast data.",
          location_name: location_name,
          units: units
        )
      end
      forecast = Forecast.new(
        temperature: raw.dig("currently", "temperature"),
        summary: raw.dig("currently", "summary"),
        icon: raw.dig("currently", "icon"),
        units: units,
        location: location_name,
        raw_data: raw
      )
      ForecastCacheService.write(lat, lon, forecast)
      return ForecastResult.new(
        forecast: forecast,
        from_cache: false,
        location_name: location_name,
        units: units
      )
    rescue => e
      return ForecastResult.new(
        error_message: "Error fetching weather data.",
        location_name: location_name,
        units: units
      )
    end
  end
end
