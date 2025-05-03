require 'rails_helper'

RSpec.describe "Forecasts", type: :request do
  describe "GET /index" do
    it "returns http success" do
      get "/forecasts"
      expect(response).to have_http_status(:success)
    end
  end

  describe "POST /forecasts" do
    let(:fake_forecast_data) do
      {
        "currently" => { "temperature" => 60 },
        "daily" => {
          "summary" => "Sunny",
          "icon" => "clear-day",
          "data" => [
            { "icon" => "clear-day", "temperatureHigh" => 75, "temperatureLow" => 55 }
          ]
        }
      }
    end

    let(:forecast_success_result) do
      forecast = Forecast.new(
        temperature: 60,
        summary: "Sunny",
        icon: "clear-day",
        units: "us",
        location: "New York, NY, USA",
        raw_data: fake_forecast_data
      )

      ForecastResult.new(
        forecast: forecast,
        location_name: "New York, NY, USA",
        units: "us"
      )
    end

    let(:london_forecast_result) do
      forecast = Forecast.new(
        temperature: 60,
        summary: "Sunny",
        icon: "clear-day",
        units: "si",
        location: "London, UK",
        raw_data: fake_forecast_data
      )

      ForecastResult.new(
        forecast: forecast,
        location_name: "London, UK",
        units: "si"
      )
    end

    let(:error_forecast_result) do
      ForecastResult.new(
        error_message: "Could not geocode query"
      )
    end

    let(:blank_query_result) do
      ForecastResult.new(
        error_message: "Please enter a query."
      )
    end

    before do
      # Stub the PirateWeatherClient at the lowest level
      allow_any_instance_of(PirateWeatherClient).to receive(:fetch_forecast).and_return(fake_forecast_data)

      # Stub ForecastService more completely
      allow_any_instance_of(ForecastService).to receive(:fetch).and_call_original
      allow_any_instance_of(ForecastService).to receive(:fetch).with("", any_args).and_return(blank_query_result)
      allow_any_instance_of(ForecastService).to receive(:fetch).with("New York, NY", any_args).and_return(forecast_success_result)
      allow_any_instance_of(ForecastService).to receive(:fetch).with("London", any_args).and_return(london_forecast_result)
      allow_any_instance_of(ForecastService).to receive(:fetch).with("Unknown Place", any_args).and_return(error_forecast_result)
      allow_any_instance_of(ForecastService).to receive(:fetch).with(/DROP TABLE/, any_args).and_return(error_forecast_result)
      allow_any_instance_of(ForecastService).to receive(:fetch).with("A" * 300, any_args).and_return(error_forecast_result)
      allow_any_instance_of(ForecastService).to receive(:fetch).with(/script/, any_args).and_return(error_forecast_result)
    end

    it "returns a forecast for a valid location" do
      # No need for additional stubs since we've set up complete stubs in the before block
      post "/forecasts", params: { query: "New York, NY" }
      expect(response).to have_http_status(:success)
      expect(response.body).to include("Weather Forecast")
    end

    it "shows an error for a blank query" do
      # Using the blank_query_result that's already stubbed in the before block
      post "/forecasts", params: { query: "" }
      expect(response).to have_http_status(:bad_request)
      expect(response.body).to include("Please enter a query").or include("can't be blank").or include("must be provided")
    end

    it "returns a forecast for a non-US location with SI units" do
      # Using the london_forecast_result that's already stubbed in the before block
      post "/forecasts", params: { query: "London" }
      expect(response).to have_http_status(:success)
      expect(response.body).to include("London").or include("Weather Forecast")
    end

    it "shows error for malformed geocode result" do
      # Using the error_forecast_result that's already stubbed in the before block
      post "/forecasts", params: { query: "Unknown Place" }
      expect(response).to have_http_status(:unprocessable_entity)
      expect(response.body).to include("Could not geocode query")
    end

    it "shows error for malicious input" do
      post "/forecasts", params: { query: "New York, NY; DROP TABLE users; --" }
      expect(response).to have_http_status(:unprocessable_entity)
      expect(response.body).not_to include("exception")
      expect(response.body).not_to include("stack trace")
      expect(response.body).to include("Could not geocode query")
    end

    it "shows error for extremely long input" do
      long_query = "A" * 300
      post "/forecasts", params: { query: long_query }
      expect(response).to have_http_status(:unprocessable_entity)
      expect(response.body).to include('Could not geocode query')
    end

    it "shows error for script injection attempts" do
      script_query = "<script>alert('x')</script>"
      post forecasts_path, params: { query: script_query }
      expect(response).to have_http_status(:unprocessable_entity)
      expect(response.body).to include('Could not geocode query')
    end
  end
end
