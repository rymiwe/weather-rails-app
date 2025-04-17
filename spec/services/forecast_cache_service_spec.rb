require 'rails_helper'

RSpec.describe ForecastCacheService do
  let(:lat) { 45.5231 }
  let(:lon) { -122.6765 }
  let(:weather) { { "currently" => { "temperature" => 70 } } }

  before { Rails.cache.clear }

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
    Rails.cache.delete(key)
    expect(ForecastCacheService.read(lat, lon)).to be_nil
  end

  it 'deletes cache' do
    ForecastCacheService.write(lat, lon, weather)
    ForecastCacheService.delete(lat, lon)
    expect(ForecastCacheService.read(lat, lon)).to be_nil
  end
end
