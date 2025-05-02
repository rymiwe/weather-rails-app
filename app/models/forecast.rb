# frozen_string_literal: true

# Forecast encapsulates all weather forecast data for a given location and time.
# This is a value object, not an ActiveRecord model.
class Forecast
  include GlobalID::Identification if defined?(GlobalID)
  
  attr_reader :temperature, :summary, :icon, :units, :location, :raw_data

  # @param temperature [Numeric] The temperature value
  # @param summary [String] Short weather summary
  # @param icon [String] Weather icon name
  # @param units [String] 'us' for Fahrenheit, 'si' for Celsius
  # @param location [String, Hash] Location info (can be string or structured)
  # @param raw_data [Hash, nil] Optional raw API data for debugging
  def initialize(temperature:, summary:, icon:, units:, location:, raw_data: nil)
    @temperature = temperature
    @summary = summary
    @icon = icon
    @units = units
    @location = location
    @raw_data = raw_data
  end

  def fahrenheit?
    units == "us"
  end

  def celsius?
    units == "si"
  end
  
  # Support for Marshal serialization
  def marshal_dump
    {
      temperature: @temperature,
      summary: @summary,
      icon: @icon,
      units: @units,
      location: @location,
      raw_data: @raw_data
    }
  end
  
  def marshal_load(data)
    @temperature = data[:temperature]
    @summary = data[:summary]
    @icon = data[:icon]
    @units = data[:units]
    @location = data[:location]
    @raw_data = data[:raw_data]
  end

  # Add more helper methods as needed
end
