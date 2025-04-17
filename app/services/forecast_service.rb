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

    cache_key = "forecast:#{lat},#{lon}"
    forecast = Rails.cache.read(cache_key)
    unless forecast.nil? || refresh
      return [forecast, true, nil, location_name]
    end

    begin
      client = PirateWeatherClient.new
      forecast = client.fetch_forecast(lat, lon)
      Rails.cache.write(cache_key, forecast, expires_in: 30.minutes)
      [forecast, false, nil, location_name]
    rescue => e
      [nil, false, 'Error fetching weather data.', location_name]
    end
  end
end
