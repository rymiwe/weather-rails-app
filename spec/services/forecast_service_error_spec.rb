require 'rails_helper'
require_relative '../../app/services/forecast_service'

RSpec.describe ForecastService, "error handling", type: :service do
  let(:query) { 'New York, NY' }
  let(:coordinates) { [ 40.7128, -74.0060 ] }
  let(:lat) { coordinates[0] }
  let(:lon) { coordinates[1] }
  let(:location_name) { "New York, NY" }
  let(:units) { "us" }

  describe "error recovery in #fetch_fresh_forecast" do
    it "handles network timeouts when fetching forecast" do
      # Create a mock client that simulates a network timeout
      mock_client = double("PirateWeatherClient")
      allow(mock_client).to receive(:fetch_forecast).and_raise(Faraday::TimeoutError)

      # Use the service instance directly to test the private method
      service = ForecastService.new(Geocoder, mock_client)

      # Call the private method using #send to test error handling
      result = service.send(:fetch_fresh_forecast, lat, lon, location_name, units)

      # Verify error handling
      expect(result).to be_a(ForecastResult)
      expect(result.error?).to be true
      expect(result.error_message).to eq("Error fetching weather data.")
      expect(result.location_name).to eq(location_name)
      expect(result.units).to eq(units)
    end

    it "handles connection failures" do
      # Create a mock client that simulates a connection failure
      mock_client = double("PirateWeatherClient")
      allow(mock_client).to receive(:fetch_forecast).and_raise(Faraday::ConnectionFailed.new("Connection refused"))

      # Use the service instance directly to test the private method
      service = ForecastService.new(Geocoder, mock_client)
      result = service.send(:fetch_fresh_forecast, lat, lon, location_name, units)

      # Verify error handling
      expect(result.error?).to be true
      expect(result.error_message).to eq("Error fetching weather data.")
    end

    it "handles JSON parsing errors" do
      # Create a mock client that returns invalid JSON
      mock_client = double("PirateWeatherClient")
      allow(mock_client).to receive(:fetch_forecast).and_raise(JSON::ParserError.new("Invalid JSON"))

      # Use the service instance directly
      service = ForecastService.new(Geocoder, mock_client)
      result = service.send(:fetch_fresh_forecast, lat, lon, location_name, units)

      # Verify error handling
      expect(result.error?).to be true
      expect(result.error_message).to eq("Error fetching weather data.")
    end

    it "handles unexpected exception types" do
      # Create a mock client that raises an unexpected error
      mock_client = double("PirateWeatherClient")
      allow(mock_client).to receive(:fetch_forecast).and_raise(StandardError.new("Something unexpected"))

      # Use the service instance directly
      service = ForecastService.new(Geocoder, mock_client)
      result = service.send(:fetch_fresh_forecast, lat, lon, location_name, units)

      # Verify error handling
      expect(result.error?).to be true
      expect(result.error_message).to eq("Error fetching weather data.")
    end

    it "logs errors when they occur" do
      # Create a mock client that raises an error
      mock_client = double("PirateWeatherClient")
      error_message = "API rate limit exceeded"
      allow(mock_client).to receive(:fetch_forecast).and_raise(RuntimeError.new(error_message))

      # Expect the logger to receive an error message
      expect(Rails.logger).to receive(:error).with(/Error fetching weather data:.*#{error_message}/)

      # Use the service instance directly
      service = ForecastService.new(Geocoder, mock_client)
      service.send(:fetch_fresh_forecast, lat, lon, location_name, units)
    end
  end

  describe "integration with ForecastCacheService" do
    it "doesn't cache failed API responses" do
      # Create a mock client that raises an error
      mock_client = double("PirateWeatherClient")
      allow(mock_client).to receive(:fetch_forecast).and_raise(RuntimeError.new("API error"))

      # Clear the cache before test
      cache_key = ForecastCacheService.key_for(lat, lon)
      Rails.cache.delete(cache_key)

      # Make the request which should fail
      result = ForecastService.fetch(query, weather_client: mock_client)

      # Verify the result has an error
      expect(result.error?).to be true

      # Verify no cache entry was created
      expect(ForecastCacheService.read(lat, lon)).to be_nil
    end
  end
end
