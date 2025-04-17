# frozen_string_literal: true

class ForecastService
  # Returns [forecast, from_cache, error_message]
  def self.fetch(address, refresh: false)
    return [nil, false, 'Please enter an address.'] if address.blank?

    geo_results = Geocoder.search(address)
    geo_result = geo_results.find { |r| r.country_code&.upcase == 'US' } || geo_results.first
    unless geo_result&.coordinates
      return [nil, false, 'Could not geocode address.']
    end
    lat, lon = geo_result.coordinates.map { |c| c.round(4) }
    location_name = [geo_result.city || geo_result.data['city'] || geo_result.data['town'] || geo_result.data['village'], geo_result.state || geo_result.data['state'], geo_result.country || geo_result.data['country']].compact.join(', ')

    forecast = Forecast.where(latitude: lat, longitude: lon).order(cached_at: :desc).first
    cache_expiry = 30.minutes.ago
    if forecast && forecast.cached_at > cache_expiry && !refresh
      return [forecast, true, nil, location_name]
    end

    begin
      client = PirateWeatherClient.new
      data = client.fetch_forecast(lat, lon)
      forecast = Forecast.create!(latitude: lat, longitude: lon, data: data, cached_at: Time.current)
      [forecast, false, nil, location_name]
    rescue => e
      [nil, false, 'Error fetching weather data.', location_name]
    end
  end
end
