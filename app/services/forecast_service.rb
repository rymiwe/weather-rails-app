# frozen_string_literal: true

class ForecastService
  class << self
    # Class method that delegates to instance method
    def fetch(query, refresh: false, geocoder: Geocoder, weather_client: PirateWeatherClient)
      new(geocoder, weather_client).fetch(query, refresh: refresh)
    end
  end

  attr_reader :geocoder, :weather_client

  def initialize(geocoder = Geocoder, weather_client = PirateWeatherClient)
    @geocoder = geocoder
    @weather_client = weather_client
  end

  # Returns a ForecastResult object
  def fetch(query, refresh: false)
    return ForecastResult.new(error_message: "Please enter an query.") if query.blank?

    geo_data = GeocodingService.lookup(query, geocoder: geocoder)
    return ForecastResult.new(error_message: "Could not geocode query.") unless geo_data

    lat = geo_data[:lat]
    lon = geo_data[:lon]
    location_name = geo_data[:location_name]
    units = geo_data[:units] || "us"

    # Try to fetch from cache first if not refreshing
    cached = ForecastCacheService.read(lat, lon)
    if cached.is_a?(Forecast) && !refresh
      return create_result_from_cache(cached, location_name, units)
    end

    # Fetch fresh data from API
    fetch_fresh_forecast(lat, lon, location_name, units)
  end

  private

  def create_result_from_cache(cached_forecast, location_name, units)
    ForecastResult.new(
      forecast: cached_forecast,
      from_cache: true,
      location_name: location_name,
      units: units
    )
  end

  def fetch_fresh_forecast(lat, lon, location_name, units)
    begin
      client = initialize_weather_client
      raw = client.fetch_forecast(lat, lon, units: units)

      if raw.nil?
        return ForecastResult.new(
          error_message: "Could not retrieve forecast data.",
          location_name: location_name,
          units: units
        )
      end

      forecast = build_forecast(raw, location_name, units)
      ForecastCacheService.write(lat, lon, forecast)

      ForecastResult.new(
        forecast: forecast,
        from_cache: false,
        location_name: location_name,
        units: units
      )
    rescue => e
      Rails.logger.error("Error fetching weather data: #{e.message}")
      ForecastResult.new(
        error_message: "Error fetching weather data.",
        location_name: location_name,
        units: units
      )
    end
  end

  def initialize_weather_client
    weather_client.is_a?(Class) ? weather_client.new : weather_client
  end

  def build_forecast(raw_data, location_name, units)
    Forecast.new(
      temperature: raw_data.dig("currently", "temperature"),
      summary: raw_data.dig("currently", "summary"),
      icon: raw_data.dig("currently", "icon"),
      units: units,
      location: location_name,
      raw_data: raw_data
    )
  end
end
