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
      # Properly stub GeocodingService instead of just the HTTP request
      allow_any_instance_of(GeocodingService).to receive(:lookup).with("New York, NY").and_return({
        lat: 40.7128,
        lon: -74.0060,
        location_name: "New York, NY, USA",
        units: "us"
      })

      post "/forecasts", params: { query: "New York, NY" }
      expect(response).to have_http_status(:success)
      expect(response.body).to include("Weather Forecast")
    end

    it "shows an error for a blank query" do
      post "/forecasts", params: { query: "" }
      expect(response.body).to include("can't be blank").or include("must be provided").or include("Please enter")
    end

    it "returns a forecast for a non-US location with SI units" do
      # Properly stub GeocodingService for London
      allow_any_instance_of(GeocodingService).to receive(:lookup).with("London").and_return({
        lat: 51.5074,
        lon: -0.1278,
        location_name: "London, UK",
        units: "si"
      })

      post "/forecasts", params: { query: "London" }
      expect(response).to have_http_status(:success)
      expect(response.body).to include("London").or include("Weather Forecast")
    end

    it "shows error for malformed geocode result" do
      # Return nil for unknown locations
      allow_any_instance_of(GeocodingService).to receive(:lookup).with("Unknown Place").and_return(nil)

      post "/forecasts", params: { query: "Unknown Place" }
      expect(response).to have_http_status(:unprocessable_entity)
      expect(response.body).to include("Could not geocode query").or include("not found")
    end

    it "shows error for malicious input" do
      # Invalid query should return nil from GeocodingService
      allow_any_instance_of(GeocodingService).to receive(:lookup).with("New York, NY; DROP TABLE users; --").and_return(nil)

      post "/forecasts", params: { query: "New York, NY; DROP TABLE users; --" }
      expect(response).to have_http_status(:unprocessable_entity)
      expect(response.body).not_to include("exception")
      expect(response.body).not_to include("stack trace")
      expect(response.body).to include("Could not geocode query").or include("not found").or include("error")
    end

    it "shows error for extremely long input" do
      long_query = "A" * 300
      allow_any_instance_of(GeocodingService).to receive(:lookup).with(long_query).and_return(nil)

      post "/forecasts", params: { query: long_query }
      expect(response).to have_http_status(:unprocessable_entity)
      expect(response.body).to include('Could not geocode query').or include('not found').or include('error')
    end

    it "shows error for script injection attempts" do
      script_query = "<script>alert('x')</script>"
      allow_any_instance_of(GeocodingService).to receive(:lookup).with(script_query).and_return(nil)

      post forecasts_path, params: { query: script_query }
      expect(response).to have_http_status(:unprocessable_entity)
      expect(response.body).to include('Could not geocode query').or include('not found').or include('error')
    end
  end
end
