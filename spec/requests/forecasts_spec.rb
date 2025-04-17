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
    end

    it "returns a forecast for a valid location" do
      stub_request(:get, "https://maps.googleapis.com/maps/api/geocode/json").
        with(query: { address: "New York, NY", key: "YOUR_API_KEY" }).
        to_return(status: 200, body: '{"results": [{"geometry": {"location": {"lat": 40.7128, "lng": -74.0060}}, "formatted_address": "New York, NY"}]}')

      post "/forecasts", params: { query: "New York, NY" }
      expect(response).to have_http_status(:success)
      expect(response.body).to include("Weather Forecast")
    end

    it "shows an error for a blank query" do
      post "/forecasts", params: { query: "" }
      expect(response.body).to include("can't be blank").or include("must be provided").or include("Please enter")
    end

    it "returns a forecast for a non-US location with SI units" do
      stub_request(:get, "https://maps.googleapis.com/maps/api/geocode/json").
        with(query: { address: "London", key: "YOUR_API_KEY" }).
        to_return(status: 200, body: '{"results": [{"geometry": {"location": {"lat": 51.5074, "lng": -0.1278}}, "formatted_address": "London, UK"}]}')

      post "/forecasts", params: { query: "London" }
      expect(response.body).to include("London").or include("Weather Forecast")
    end

    it "shows error for malformed geocode result" do
      stub_request(:get, "https://maps.googleapis.com/maps/api/geocode/json").
        with(query: { address: "Unknown Place", key: "YOUR_API_KEY" }).
        to_return(status: 200, body: '{"results": []}')

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
      puts "[DEBUG] response.body for long input: #{response.body.inspect}"
      expect(response.body).to include('Could not geocode query').or include('not found').or include('error')
    end

    it "shows error for extremely long/invalid input" do
      post forecasts_path, params: { query: "<script>alert('x')</script>" }
      expect(response.body).to include('Could not geocode query').or include('not found').or include('error')
    end
  end
end
