# frozen_string_literal: true

require "faraday"

class PirateWeatherClient
  API_BASE_URL = "https://api.pirateweather.net/forecast"

  def initialize(api_key: nil)
    @api_key = api_key || Rails.application.credentials.dig(:weather, :pirate_api_key)
    raise ArgumentError, "Pirate Weather API key missing" if @api_key.nil? || @api_key.empty?
  end

  # Returns parsed JSON or raises
  def fetch_forecast(lat, lon, units: "us")
    url = "#{API_BASE_URL}/#{@api_key}/#{lat},#{lon}?units=#{units}&icon=pirate"
    response = Faraday.get(url)
    unless response.success?
      raise "Pirate Weather API error: #{response.status}"
    end
    JSON.parse(response.body)
  end
end
