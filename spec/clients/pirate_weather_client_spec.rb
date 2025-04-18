# frozen_string_literal: true

require 'rails_helper'
require 'faraday'

RSpec.describe PirateWeatherClient do
  let(:api_key) { 'test_api_key' }
  let(:lat) { 37.7749 }
  let(:lon) { -122.4194 }
  let(:units) { 'us' }
  let(:client) { described_class.new(api_key: api_key) }

  describe '#initialize' do
    it 'sets the API key when provided' do
      expect(client.instance_variable_get(:@api_key)).to eq(api_key)
    end

    it 'raises an error if API key is missing' do
      allow(Rails.application.credentials).to receive(:dig).with(:weather, :pirate_api_key).and_return(nil)
      expect { described_class.new(api_key: nil) }.to raise_error(ArgumentError, /API key missing/)
      expect { described_class.new(api_key: '') }.to raise_error(ArgumentError, /API key missing/)
    end
  end

  describe '#fetch_forecast' do
    let(:url) { "https://api.pirateweather.net/forecast/#{api_key}/#{lat},#{lon}?units=#{units}&icon=pirate" }
    let(:response_body) { '{"currently":{"summary":"Clear"}}' }

    before do
      stub_request(:get, url)
        .to_return(status: status, body: response_body, headers: { 'Content-Type' => 'application/json' })
    end

    context 'when the API returns success' do
      let(:status) { 200 }

      it 'returns parsed JSON' do
        result = client.fetch_forecast(lat, lon, units: units)
        expect(result).to be_a(Hash)
        expect(result['currently']['summary']).to eq('Clear')
      end
    end

    context 'when the API returns an error' do
      let(:status) { 500 }

      it 'raises an error with the status' do
        expect { client.fetch_forecast(lat, lon, units: units) }
          .to raise_error(RuntimeError, /Pirate Weather API error: 500/)
      end
    end
  end
end
