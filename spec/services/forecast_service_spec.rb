require 'rails_helper'
require 'ostruct'
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
    allow(Geocoder).to receive(:search).and_return([
      OpenStruct.new(
        coordinates: [ 40.7128, -74.0060 ],
        country_code: 'US',
        city: 'New York',
        state: 'NY',
        country: 'US',
        data: {}
      )
    ])
    allow_any_instance_of(PirateWeatherClient).to receive(:fetch_forecast).and_return(fake_forecast)
  end

  describe '.fetch' do
    it 'caches the forecast for an query' do
      expect(ForecastCacheService.read(lat, lon)).to be_nil
      forecast, from_cache, error, location = described_class.fetch(query)

      expect(forecast).to include(fake_forecast)
      expect(from_cache).to be_falsey
      cached = ForecastCacheService.read(lat, lon)
      expect(cached).to include(fake_forecast)
    end

    it 'returns cached forecast on subsequent calls' do
      described_class.fetch(query)
      forecast, from_cache, error, location = described_class.fetch(query)
      expect(forecast).to include(fake_forecast)
      expect(from_cache).to be_truthy
    end

    it 'fetches new forecast when refresh is true' do
      described_class.fetch(query)
      new_forecast = fake_forecast.merge("currently" => { "temperature" => 80 })
      allow_any_instance_of(PirateWeatherClient).to receive(:fetch_forecast).and_return(new_forecast)
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
      allow_any_instance_of(PirateWeatherClient).to receive(:fetch_forecast).and_raise(StandardError, "API error")
      forecast, from_cache, error, location = described_class.fetch(query)
      expect(forecast).to be_nil
      expect(error).to be_present
    end

    it 'handles missing/malformed forecast data' do
      allow_any_instance_of(PirateWeatherClient).to receive(:fetch_forecast).and_return(nil)
      forecast, from_cache, error, location = described_class.fetch(query)
      expect(forecast).to be_nil
      expect(error).to be_present
    end

    it 'handles non-US geocoding results' do
      non_us_result = OpenStruct.new(
        coordinates: [ 51.5074, -0.1278 ],
        country_code: 'GB',
        city: 'London',
        state: 'England',
        country: 'United Kingdom',
        data: {}
      )
      allow(Geocoder).to receive(:search).and_return([ non_us_result ])
      forecast, from_cache, error, location, units = described_class.fetch('London')
      expect(location).to include('London')
      expect(units).to eq('si')
    end

    it 'handles ambiguous/multiple geocoding results (picks US if present)' do
      us_result = OpenStruct.new(
        coordinates: [ 37.7749, -122.4194 ],
        country_code: 'US',
        city: 'San Francisco',
        state: 'CA',
        country: 'US',
        data: {}
      )
      gb_result = OpenStruct.new(
        coordinates: [ 51.5074, -0.1278 ],
        country_code: 'GB',
        city: 'London',
        state: 'England',
        country: 'United Kingdom',
        data: {}
      )
      allow(Geocoder).to receive(:search).and_return([ gb_result, us_result ])
      forecast, from_cache, error, location, units = described_class.fetch('Ambiguous')
      expect(location).to include('San Francisco')
      expect(units).to eq('us')
    end

    it 'handles missing city/state/country gracefully' do
      partial_result = OpenStruct.new(
        coordinates: [ 10, 10 ],
        country_code: 'US',
        city: nil,
        state: nil,
        country: nil,
        data: {}
      )
      allow(Geocoder).to receive(:search).and_return([ partial_result ])
      forecast, from_cache, error, location, units = described_class.fetch('Nowhere')
      expect(location).to be_a(String)
    end

    it 'handles geocoder returning empty array' do
      allow(Geocoder).to receive(:search).and_return([])
      forecast, from_cache, error, location = described_class.fetch('Unknown Place')
      expect(forecast).to be_nil
      expect(error).to include('geocode')
    end

    it 'handles malformed forecast hash (missing keys)' do
      allow_any_instance_of(PirateWeatherClient).to receive(:fetch_forecast).and_return({})
      forecast, from_cache, error, location = described_class.fetch(query)
      expect(forecast).to eq({})
      expect(error).to be_nil.or be_present
    end
  end
end
