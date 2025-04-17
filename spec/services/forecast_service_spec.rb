require 'rails_helper'
require 'ostruct'

RSpec.describe WeatherService do
  let(:query) { 'New York, NY' }
  let(:coordinates) { [40.7128, -74.0060] }
  let(:lat) { coordinates[0] }
  let(:lon) { coordinates[1] }
  let(:cache_key) { WeatherCacheService.key_for(lat, lon) }

  let(:fake_forecast) { { "currently" => { "temperature" => 75 }, "daily" => [{ "icon" => "clear-day" }] } }

  before do
    Rails.cache.clear
    allow(Geocoder).to receive(:search).and_return([
      OpenStruct.new(
        coordinates: [40.7128, -74.0060],
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
      expect(WeatherCacheService.read(lat, lon)).to be_nil
      forecast, from_cache, error, location = described_class.fetch(query)

      expect(forecast).to eq(fake_forecast)
      expect(from_cache).to be_falsey
      expect(WeatherCacheService.read(lat, lon)).to eq(fake_forecast)
    end

    it 'returns cached forecast on subsequent calls' do
      described_class.fetch(query)
      forecast, from_cache, error, location = described_class.fetch(query)
      expect(forecast).to eq(fake_forecast)
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
  end
end
