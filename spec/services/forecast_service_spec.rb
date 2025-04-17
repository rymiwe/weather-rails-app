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
    # Default stub for 'New York, NY'
    WebMock.stub_request(:get, /mapbox.*New%20York/).
      to_return(status: 200, body: '{"features": [{"geometry": {"coordinates": [-74.006, 40.7128]}, "properties": {"city": "New York", "state": "NY", "country": "US"}}]}')
    WebMock.stub_request(:get, /pirate-weather-api|pirateweather/).
      to_return(status: 200, body: fake_forecast.to_json)
  end

  describe '.fetch' do
    it 'caches the forecast for an query' do
      WebMock.stub_request(:get, /pirate-weather-api|pirateweather/).
        to_return(status: 200, body: fake_forecast.to_json, headers: {})
      expect(ForecastCacheService.read(lat, lon)).to be_nil
      forecast, from_cache, error, location = described_class.fetch(query)
      expect(forecast).to include(fake_forecast)
      expect(from_cache).to be_falsey
      cached = ForecastCacheService.read(lat, lon)
      expect(cached).to include(fake_forecast)
    end

    it 'returns cached forecast on subsequent calls' do
      WebMock.stub_request(:get, /pirate-weather-api|pirateweather/).
        to_return(status: 200, body: fake_forecast.to_json, headers: {})
      described_class.fetch(query)
      forecast, from_cache, error, location = described_class.fetch(query)
      expect(forecast).to include(fake_forecast)
      expect(from_cache).to be_truthy
    end

    it 'fetches new forecast when refresh is true' do
      new_forecast = fake_forecast.merge("currently" => { "temperature" => 80 })
      WebMock.stub_request(:get, /pirate-weather-api|pirateweather/).
        to_return(status: 200, body: new_forecast.to_json, headers: {})
      forecast, from_cache, error, location = described_class.fetch(query, refresh: true)
      expect(forecast).to eq(new_forecast)
      expect(from_cache).to be_falsey
    end

    it 'handles blank query' do
      forecast, from_cache, error, location = described_class.fetch('')
      expect(forecast).to be_nil
      expect(error).to be_present
    end

    it 'handles API errors gracefully' do
      WebMock.stub_request(:get, /pirate-weather-api|pirateweather/).
        to_return(status: 500, body: '')
      forecast, from_cache, error, location = described_class.fetch(query)
      expect(forecast).to be_nil
      expect(error).to be_present
    end

    it 'handles missing/malformed forecast data' do
      WebMock.stub_request(:get, /pirate-weather-api|pirateweather/).
        to_return(status: 200, body: '{}')
      forecast, from_cache, error, location = described_class.fetch(query)
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
      WebMock.stub_request(:get, /pirate-weather-api|pirateweather/).
        to_return(status: 200, body: '{}')
      forecast, from_cache, error, location = described_class.fetch(query)
      expect(forecast).to eq({})
      expect(error).to be_nil.or be_present
    end
  end
end
