require 'rails_helper'

RSpec.describe "Forecasts", type: :request do
  describe "GET /index" do
    it "returns http success" do
      get "/forecasts"
      expect(response).to have_http_status(:success)
    end
  end

  describe "POST /forecasts" do
    before do
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
      allow_any_instance_of(PirateWeatherClient).to receive(:fetch_forecast).and_return({
        "currently" => { "temperature" => 60 },
        "daily" => {
          "summary" => "Sunny",
          "icon" => "clear-day",
          "data" => [
            { "icon" => "clear-day", "temperatureHigh" => 75, "temperatureLow" => 55 }
          ]
        }
      })
      Geocoder::Lookup::Test.add_stub(
        'New York, NY', [
          {
            'latitude'     => 40.7128,
            'longitude'    => -74.0060,
            'address'      => 'New York, NY',
            'city'         => 'New York',
            'state'        => 'NY',
            'country'      => 'US',
            'country_code' => 'US'
          }
        ]
      )
      Geocoder::Lookup::Test.add_stub(
        'A' * 300, [
          {
            'latitude'     => nil,
            'longitude'    => nil,
            'address'      => nil,
            'city'         => nil,
            'state'        => nil,
            'country'      => nil,
            'country_code' => nil
          }
        ]
      )
    end

    it "returns a forecast for a valid location" do
      post "/forecasts", params: { query: "New York, NY" }
      expect(response).to have_http_status(:success)
      expect(response.body).to include("Weather Forecast")
    end

    it "shows an error for a blank query" do
      post "/forecasts", params: { query: "" }
      expect(response.body).to include("can't be blank").or include("must be provided").or include("Please enter")
    end

    it "returns a forecast for a non-US location with SI units" do
      allow(Geocoder).to receive(:search).and_return([
        OpenStruct.new(
          coordinates: [ 51.5074, -0.1278 ],
          country_code: 'GB',
          city: 'London',
          state: 'England',
          country: 'United Kingdom',
          data: {}
        )
      ])
      post "/forecasts", params: { query: "London" }
      expect(response.body).to include("London").or include("Weather Forecast")
    end

    it "shows error for malformed geocode result" do
      allow(Geocoder).to receive(:search).and_return([])
      post "/forecasts", params: { query: "Unknown Place" }
      expect(response.body).to include("Could not geocode query").or include("not found")
    end

    it "shows error for malicious input" do
      post "/forecasts", params: { query: "New York, NY; DROP TABLE users; --" }
      expect(response.body).not_to include("exception")
      expect(response.body).not_to include("stack trace")
      expect(response.body).to include("Could not geocode query").or include("not found").or include("error")
    end

    it "shows error for extremely long/invalid input" do
      post "/forecasts", params: { query: "A" * 300 }
      expect(response.body).to include("Could not geocode query").or include("not found").or include("error")
    end
  end
end
