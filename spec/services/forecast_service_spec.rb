require 'rails_helper'
require_relative '../../app/services/forecast_service'

RSpec.describe ForecastService, type: :service do
  let(:query) { 'New York, NY' }
  let(:coordinates) { [ 40.7128, -74.0060 ] }
  let(:lat) { coordinates[0] }
  let(:lon) { coordinates[1] }
  let(:cache_key) { ForecastCacheService.key_for(lat, lon) }

  let(:fake_forecast) do
    {
      "currently" => { "temperature" => 75 },
      "daily" => {
        "summary" => "Sunny",
        "icon" => "clear-day",
        "data" => [
          { "icon" => "clear-day", "temperatureHigh" => 80, "temperatureLow" => 60 }
        ]
      }
    }
  end

  before do
    Rails.cache.clear
    # No need to define geocoder stubs here, they're already defined in spec/support/geocoder_stubs.rb

    # Default Pirate Weather API stub as a fallback
    WebMock.stub_request(:get, /api\.pirateweather\.net/).
      to_return(status: 200, body: fake_forecast.to_json)
  end

  describe '.fetch' do
    it 'caches the forecast for an query' do
      # Create a mock client that returns our test forecast
      mock_client = double("PirateWeatherClient")
      allow(mock_client).to receive(:fetch_forecast).and_return(fake_forecast)

      # Clear the cache and verify it's empty
      Rails.cache.clear
      expect(ForecastCacheService.read(lat, lon)).to be_nil

      # First fetch should use the mock client and store in cache
      result = described_class.fetch(query, weather_client: mock_client)

      # Verify forecast matches and wasn't from cache
      expect(result).to be_a(ForecastResult)
      expect(result.forecast).to be_a(Forecast)
expect(result.forecast.temperature).to eq(75)
      # Add more attribute checks as needed
      expect(result.from_cache).to be_falsey

      # Verify forecast was stored in cache
      cached = ForecastCacheService.read(lat, lon)
      expect(cached).to be_a(Forecast)
      expect(cached.raw_data["currently"]).to eq(fake_forecast["currently"])
      expect(cached.raw_data["daily"]).to eq(fake_forecast["daily"])
    end

    it 'returns cached forecast on subsequent calls' do
      # Create a mock client that returns our test forecast
      mock_client = double("PirateWeatherClient")
      allow(mock_client).to receive(:fetch_forecast).and_return(fake_forecast)

      # Clear the cache and make first call to populate cache
      Rails.cache.clear
      described_class.fetch(query, weather_client: mock_client)

      # Verify the mock isn't called for the second fetch - should get cached version
      # Now verify a subsequent call returns the cached forecast
      result = described_class.fetch(query)

      # Should receive forecast from cache
      expect(result).to be_a(ForecastResult)
      expect(result.forecast).to be_a(Forecast)
      expect(result.forecast.raw_data["currently"]).to eq(fake_forecast["currently"])
      expect(result.forecast.raw_data["daily"]).to eq(fake_forecast["daily"])
      expect(result.from_cache).to be_truthy
    end

    it 'fetches new forecast when refresh is true' do
      # Create a mock client that returns our custom forecast
      new_forecast = fake_forecast.merge("currently" => { "temperature" => 80 })
      mock_client = double("PirateWeatherClient")
      allow(mock_client).to receive(:fetch_forecast).and_return(new_forecast)

      # Use the mock client explicitly
      result = described_class.fetch(query, refresh: true, weather_client: mock_client)

      # Verify the forecast matches our special mock data
      expect(result.forecast.raw_data["currently"]["temperature"]).to eq(80)
      expect(result.from_cache).to be_falsey
    end

    it 'handles blank query' do
      result = described_class.fetch('')
      expect(result.forecast).to be_nil
      expect(result.error_message).to be_present
    end

    it 'handles API errors gracefully' do
      # Create a mock client that raises an error
      mock_client = double("PirateWeatherClient")
      allow(mock_client).to receive(:fetch_forecast).and_raise(RuntimeError.new("API error"))

      # Use the mock client explicitly
      result = described_class.fetch(query, weather_client: mock_client)

      # API errors should result in nil forecast and an error message
      expect(result.forecast).to be_nil
      expect(result.error_message).to eq("Error fetching weather data.")
    end

    it 'handles missing/malformed forecast data' do
      # Create a mock client that returns an empty hash
      mock_client = double("PirateWeatherClient")
      allow(mock_client).to receive(:fetch_forecast).and_return({})

      # Use the mock client explicitly
      result = described_class.fetch(query, weather_client: mock_client)

      # An empty JSON object should be parsed as an empty hash
      expect(result.forecast).to be_a(Forecast)
      expect(result.forecast.temperature).to be_nil
      expect(result.forecast.raw_data).to eq({})
      expect(result.error_message).to be_nil
    end

    it 'handles non-US geocoding results' do
      non_us_result = {
        coordinates: [ 51.5074, -0.1278 ],
        country_code: 'GB',
        city: 'London',
        state: 'England',
        country: 'United Kingdom',
        data: {}
      }
      stub_request(:get, "https://api.mapbox.com/geocoding/v5/mapbox.places/London.json").
        with(headers: { 'User-Agent' => 'Faraday v2.3.0' }).
        to_return(status: 200, body: '{"features": [{"geometry": {"coordinates": [-0.1278, 51.5074]}, "properties": {"city": "London", "state": "England", "country": "United Kingdom"}}]}', headers: {})
      result = described_class.fetch('London')
      expect(result.location_name).to include('London')
      expect(result.units).to eq('si')
    end

    it 'handles ambiguous/multiple geocoding results (picks US if present)' do
      us_result = {
        coordinates: [ 37.7749, -122.4194 ],
        country_code: 'US',
        city: 'San Francisco',
        state: 'CA',
        country: 'US',
        data: {}
      }
      gb_result = {
        coordinates: [ 51.5074, -0.1278 ],
        country_code: 'GB',
        city: 'London',
        state: 'England',
        country: 'United Kingdom',
        data: {}
      }
      stub_request(:get, "https://api.mapbox.com/geocoding/v5/mapbox.places/Ambiguous.json").
        with(headers: { 'User-Agent' => 'Faraday v2.3.0' }).
        to_return(status: 200, body: '{"features": [{"geometry": {"coordinates": [-122.4194, 37.7749]}, "properties": {"city": "San Francisco", "state": "CA", "country": "US"}}, {"geometry": {"coordinates": [-0.1278, 51.5074]}, "properties": {"city": "London", "state": "England", "country": "United Kingdom"}}]}', headers: {})
      result = described_class.fetch('Ambiguous')
      expect(result.location_name).to include('San Francisco')
      expect(result.units).to eq('us')
    end

    it 'handles missing city/state/country gracefully' do
      partial_result = {
        coordinates: [ 10, 10 ],
        country_code: 'US',
        city: nil,
        state: nil,
        country: nil,
        data: {}
      }
      stub_request(:get, "https://api.mapbox.com/geocoding/v5/mapbox.places/Nowhere.json").
        with(headers: { 'User-Agent' => 'Faraday v2.3.0' }).
        to_return(status: 200, body: '{"features": [{"geometry": {"coordinates": [10, 10]}, "properties": {}}]}', headers: {})
      result = described_class.fetch('Nowhere')
      expect(result.location_name).to be_a(String)
    end

    it 'handles geocoder returning empty array' do
      stub_request(:get, "https://api.mapbox.com/geocoding/v5/mapbox.places/Unknown Place.json").
        with(headers: { 'User-Agent' => 'Faraday v2.3.0' }).
        to_return(status: 200, body: '{"features": []}', headers: {})
      result = described_class.fetch('Unknown Place')
      expect(result.forecast).to be_nil
      expect(result.error_message).to include('geocode')
    end

    it 'handles malformed forecast hash (missing keys)' do
      # Create a mock client that returns an empty hash
      mock_client = double("PirateWeatherClient")
      allow(mock_client).to receive(:fetch_forecast).and_return({})

      # Use the mock client explicitly
      result = described_class.fetch(query, weather_client: mock_client)

      # An empty hash should be handled properly
      expect(result.forecast).to be_a(Forecast)
      expect(result.forecast.temperature).to be_nil
      expect(result.forecast.raw_data).to eq({})
      expect(result.error_message).to be_nil
    end
    
    it 'handles nil response from weather client' do
      # Create a mock client that returns nil
      mock_client = double("PirateWeatherClient")
      allow(mock_client).to receive(:fetch_forecast).and_return(nil)

      # Use the mock client explicitly
      result = described_class.fetch(query, weather_client: mock_client)

      # Nil response should result in error message
      expect(result.forecast).to be_nil
      expect(result.error_message).to eq("Could not retrieve forecast data.")
      expect(result.location_name).to include("New York")
    end
    
    it 'handles different weather client types correctly' do
      # Test with an instance (direct use)
      mock_instance = instance_double("PirateWeatherClient")
      allow(mock_instance).to receive(:is_a?).with(Class).and_return(false)
      allow(mock_instance).to receive(:fetch_forecast).and_return(fake_forecast)
      
      result = described_class.fetch(query, weather_client: mock_instance)
      expect(result.forecast).to be_a(Forecast)
      expect(result.error_message).to be_nil

      # For testing a class, we can use a custom test class
      test_client_class = Class.new do
        def fetch_forecast(*args)
          {
            "currently" => { "temperature" => 75 },
            "daily" => {
              "summary" => "Sunny", 
              "icon" => "clear-day"
            }
          }
        end
      end
      
      result = described_class.fetch(query, weather_client: test_client_class)
      expect(result.forecast).to be_a(Forecast)
      expect(result.error_message).to be_nil
    end
  end
end
