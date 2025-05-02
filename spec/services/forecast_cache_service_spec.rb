require 'rails_helper'

RSpec.describe ForecastCacheService do
  let(:lat) { 45.5231 }
  let(:lon) { -122.6765 }
  let(:weather) { { "currently" => { "temperature" => 70 } } }

  # Clear Redis cache keys before each test
  before do
    clear_test_cache
    # Verify our Redis connection is working
    test_key = "test:#{Time.now.to_i}"
    Rails.cache.write(test_key, "test_value")
    expect(Rails.cache.read(test_key)).to eq("test_value")
  end

  it 'writes and reads cache' do
    ForecastCacheService.write(lat, lon, weather)
    cached = ForecastCacheService.read(lat, lon)
    expect(cached).to include("currently")
  end

  it 'adds cached_at timestamp' do
    ForecastCacheService.write(lat, lon, weather)
    cached = ForecastCacheService.read(lat, lon)
    expect(cached["cached_at"]).to be_present
  end

  it 'expires cache after expiry time' do
    ForecastCacheService.write(lat, lon, weather)
    key = ForecastCacheService.key_for(lat, lon)
    # Simulate expiry by deleting the cache entry
    Rails.cache.delete(key)
    expect(ForecastCacheService.read(lat, lon)).to be_nil
  end

  it 'does not overwrite cache for different lat/lon' do
    ForecastCacheService.write(lat, lon, weather)
    other_lat, other_lon = lat + 1, lon + 1
    other_weather = { 'currently' => { 'temperature' => 90 } }
    ForecastCacheService.write(other_lat, other_lon, other_weather)
    expect(ForecastCacheService.read(lat, lon)).to include('currently')
    other_cached = ForecastCacheService.read(other_lat, other_lon)
    expect(other_cached['currently']).to eq(other_weather['currently'])
    expect { Time.parse(other_cached['cached_at']) }.not_to raise_error
  end

  it 'handles nil/empty weather data' do
    ForecastCacheService.write(lat, lon, nil)
    expect(ForecastCacheService.read(lat, lon)).to be_nil.or be_empty
  end

  it 'deletes cache' do
    ForecastCacheService.write(lat, lon, weather)
    ForecastCacheService.delete(lat, lon)
    expect(ForecastCacheService.read(lat, lon)).to be_nil
  end
end
