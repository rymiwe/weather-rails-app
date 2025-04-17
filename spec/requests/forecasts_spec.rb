require 'rails_helper'

RSpec.describe "Forecasts", type: :request do
  describe "GET /index" do
    it "returns http success" do
      get "/forecasts"
      expect(response).to have_http_status(:success)
    end
  end

  describe "POST /forecasts" do
    it "returns a forecast for a valid location" do
      post "/forecasts", params: { query: "New York, NY" }
      expect(response).to have_http_status(:success)
      expect(response.body).to include("Weather Forecast")
    end

    it "shows an error for a blank query" do
      post "/forecasts", params: { query: "" }
      expect(response.body).to include("can't be blank").or include("must be provided").or include("Please enter")
    end
  end
end
