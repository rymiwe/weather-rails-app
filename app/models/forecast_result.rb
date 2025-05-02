# frozen_string_literal: true

# ForecastResult encapsulates the complete result of a forecast fetch operation
# including the forecast itself, metadata, and error information.
class ForecastResult
  attr_reader :forecast, :from_cache, :error_message, :location_name, :units

  # @param forecast [Forecast, nil] The forecast object or nil if unavailable
  # @param from_cache [Boolean] Whether the forecast was retrieved from cache
  # @param error_message [String, nil] Error message if fetch failed
  # @param location_name [String] Name of the location
  # @param units [String] Units used ('us' or 'si')
  def initialize(forecast: nil, from_cache: false, error_message: nil, location_name: nil, units: 'us')
    @forecast = forecast
    @from_cache = from_cache
    @error_message = error_message
    @location_name = location_name
    @units = units
  end

  # Helper to check if there is a valid forecast
  def success?
    forecast.present? && error_message.nil?
  end

  # Helper to check if there was an error
  def error?
    error_message.present?
  end
end
