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
    # Geocoder test stubs for all queries used in tests
    Geocoder::Lookup::Test.add_stub(
      "New York, NY", [
        {
          'latitude'     => 40.7128,
          'longitude'    => -74.006,
          'address'      => 'New York, NY, USA',
          'city'         => 'New York',
          'state'        => 'NY',
          'country'      => 'US',
          'country_code' => 'US'
        }
      ]
    )
    Geocoder::Lookup::Test.add_stub(
      "London", [
        {
          'latitude'     => 51.5074,
          'longitude'    => -0.1278,
          'address'      => 'London, England, United Kingdom',
          'city'         => 'London',
          'state'        => 'England',
          'country'      => 'United Kingdom',
          'country_code' => 'GB'
        }
      ]
    )
    Geocoder::Lookup::Test.add_stub(
      "Ambiguous", [
        {
          'latitude'     => 37.7749,
          'longitude'    => -122.4194,
          'address'      => 'San Francisco, CA, USA',
          'city'         => 'San Francisco',
          'state'        => 'CA',
          'country'      => 'US',
          'country_code' => 'US'
        },
        {
          'latitude'     => 51.5074,
          'longitude'    => -0.1278,
          'address'      => 'London, England, United Kingdom',
          'city'         => 'London',
          'state'        => 'England',
          'country'      => 'United Kingdom',
          'country_code' => 'GB'
        }
      ]
    )
    Geocoder::Lookup::Test.add_stub(
      "Nowhere", [
        {
          'latitude'     => 10.0,
          'longitude'    => 10.0,
          'address'      => 'Nowhere',
          'city'         => nil,
          'state'        => nil,
          'country'      => nil,
          'country_code' => 'US'
        }
      ]
    )
    Geocoder::Lookup::Test.add_stub("Unknown Place", [])
    Geocoder::Lookup::Test.add_stub("New York, NY; DROP TABLE users; --", [])
    Geocoder::Lookup::Test.add_stub("AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA", [])
    Geocoder::Lookup::Test.add_stub("<script>alert('x')</script>", [])

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
      forecast, from_cache, error, location = described_class.fetch(query, weather_client: mock_client)

      # Verify forecast matches and wasn't from cache
      expect(forecast).to eq(fake_forecast)
      expect(from_cache).to be_falsey

      # Verify forecast was stored in cache
      cached = ForecastCacheService.read(lat, lon)
      expect(cached).to be_a(Hash)
      expect(cached["currently"]).to eq(fake_forecast["currently"])
      expect(cached["daily"]).to eq(fake_forecast["daily"])
    end

    it 'returns cached forecast on subsequent calls' do
      # Create a mock client that returns our test forecast
      mock_client = double("PirateWeatherClient")
      allow(mock_client).to receive(:fetch_forecast).and_return(fake_forecast)

      # Clear the cache and make first call to populate cache
      Rails.cache.clear
      described_class.fetch(query, weather_client: mock_client)

      # Verify the mock isn't called for the second fetch - should get cached version
      expect(mock_client).not_to receive(:fetch_forecast)
      forecast, from_cache, error, location = described_class.fetch(query, weather_client: mock_client)

      # Verify forecast was returned from cache
      expect(forecast).to be_a(Hash)
      expect(forecast["currently"]).to eq(fake_forecast["currently"])
      expect(forecast["daily"]).to eq(fake_forecast["daily"])
      expect(from_cache).to be_truthy
    end

    it 'fetches new forecast when refresh is true' do
      # Create a mock client that returns our custom forecast
      new_forecast = fake_forecast.merge("currently" => { "temperature" => 80 })
      mock_client = double("PirateWeatherClient")
      allow(mock_client).to receive(:fetch_forecast).and_return(new_forecast)

      # Use the mock client explicitly
      forecast, from_cache, error, location = described_class.fetch(query, refresh: true, weather_client: mock_client)

      # Verify the forecast matches our special mock data
      expect(forecast["currently"]["temperature"]).to eq(80)
      expect(from_cache).to be_falsey
    end

    it 'handles blank query' do
      forecast, from_cache, error, location = described_class.fetch('')
      expect(forecast).to be_nil
      expect(error).to be_present
    end

    it 'handles API errors gracefully' do
      # Create a mock client that raises an error
      mock_client = double("PirateWeatherClient")
      allow(mock_client).to receive(:fetch_forecast).and_raise(RuntimeError.new("API error"))

      # Use the mock client explicitly
      forecast, from_cache, error, location = described_class.fetch(query, weather_client: mock_client)

      # API errors should result in nil forecast and an error message
      expect(forecast).to be_nil
      expect(error).to eq("Error fetching weather data.")
    end

    it 'handles missing/malformed forecast data' do
      # Create a mock client that returns an empty hash
      mock_client = double("PirateWeatherClient")
      allow(mock_client).to receive(:fetch_forecast).and_return({})

      # Use the mock client explicitly
      forecast, from_cache, error, location = described_class.fetch(query, weather_client: mock_client)

      # An empty JSON object should be parsed as an empty hash
      expect(forecast).to eq({})
      expect(error).to be_nil
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
      forecast, from_cache, error, location, units = described_class.fetch('London')
      expect(location).to include('London')
      expect(units).to eq('si')
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
      forecast, from_cache, error, location, units = described_class.fetch('Ambiguous')
      expect(location).to include('San Francisco')
      expect(units).to eq('us')
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
      forecast, from_cache, error, location, units = described_class.fetch('Nowhere')
      expect(location).to be_a(String)
    end

    it 'handles geocoder returning empty array' do
      stub_request(:get, "https://api.mapbox.com/geocoding/v5/mapbox.places/Unknown Place.json").
        with(headers: { 'User-Agent' => 'Faraday v2.3.0' }).
        to_return(status: 200, body: '{"features": []}', headers: {})
      forecast, from_cache, error, location = described_class.fetch('Unknown Place')
      expect(forecast).to be_nil
      expect(error).to include('geocode')
    end

    it 'handles malformed forecast hash (missing keys)' do
      # Create a mock client that returns an empty hash
      mock_client = double("PirateWeatherClient")
      allow(mock_client).to receive(:fetch_forecast).and_return({})

      # Use the mock client explicitly
      forecast, from_cache, error, location = described_class.fetch(query, weather_client: mock_client)

      # An empty hash should be handled properly
      expect(forecast).to eq({})
      expect(error).to be_nil
    end
  end
end
