require 'rails_helper'
require_relative '../../app/services/geocoding_service'

RSpec.describe GeocodingService, type: :service do
  describe '.lookup' do
    # Set up a ZIP code test stub - add this to the shared stubs
    before do
      Geocoder::Lookup::Test.add_stub(
        "10001", [
          {
            'latitude'     => 40.7508,
            'longitude'    => -73.9973,
            'address'      => {
              'city'    => 'New York',
              'state'   => 'NY',
              'country' => 'United States'
            },
            'country_code' => 'US'
          }
        ]
      )
      
      Geocoder::Lookup::Test.add_stub(
        "Incomplete Address", [
          {
            'latitude'     => 40.7128,
            'longitude'    => -74.006,
            'address'      => {
              'city'    => nil,
              'state'   => nil,
              'country' => nil
            },
            'country_code' => 'US'
          }
        ]
      )
    end
    
    it 'returns coordinates and location info for a valid query' do
      result = described_class.lookup("New York, NY")
      
      expect(result).to be_a(Hash)
      expect(result[:lat]).to eq(40.7128)
      expect(result[:lon]).to eq(-74.006)
      expect(result[:location_name]).to eq("New York, NY, United States")
      expect(result[:units]).to eq("us")
    end
    
    it 'applies US units for US locations' do
      result = described_class.lookup("New York, NY")
      expect(result[:units]).to eq("us")
    end
    
    it 'applies SI units for non-US locations' do
      result = described_class.lookup("London")
      expect(result[:units]).to eq("si")
    end
    
    it 'handles incomplete address data' do
      result = described_class.lookup("Incomplete Address")
      expect(result[:location_name]).to eq("")
      expect(result[:lat]).to eq(40.7128)
      expect(result[:lon]).to eq(-74.006)
    end
    
    it 'returns nil for invalid or non-geocodable queries' do
      result = described_class.lookup("Invalid Query")
      expect(result).to be_nil
    end
    
    it 'adds countrycodes parameter for US ZIP codes' do
      mock_geocoder = class_double("Geocoder")
      allow(mock_geocoder).to receive(:search).with("10001", { params: { countrycodes: "us" } }).and_return([
        double("Result", data: { 
          'latitude' => 40.7508, 
          'longitude' => -73.9973,
          'address' => { 'city' => 'New York', 'state' => 'NY', 'country' => 'United States' },
          'country_code' => 'US'
        })
      ])
      
      result = described_class.lookup("10001", geocoder: mock_geocoder)
      expect(result).not_to be_nil
    end
    
    it 'handles geocoding service errors gracefully' do
      error_geocoder = class_double("Geocoder")
      allow(error_geocoder).to receive(:search).and_raise(ArgumentError.new("Invalid argument"))
      
      result = described_class.lookup("Error Query", geocoder: error_geocoder)
      expect(result).to be_nil
    end
  end
end
