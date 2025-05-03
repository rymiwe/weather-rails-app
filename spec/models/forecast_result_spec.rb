require 'rails_helper'

RSpec.describe ForecastResult do
  let(:forecast) { Forecast.new(temperature: 75, summary: "Sunny", icon: "clear-day", units: "us", location: "Portland, OR") }

  describe "#initialize" do
    it "initializes with a forecast" do
      result = ForecastResult.new(forecast: forecast)
      expect(result.forecast).to eq(forecast)
      expect(result.from_cache).to be false
      expect(result.error_message).to be_nil
    end

    it "initializes with from_cache flag" do
      result = ForecastResult.new(forecast: forecast, from_cache: true)
      expect(result.from_cache).to be true
    end

    it "initializes with location_name" do
      result = ForecastResult.new(forecast: forecast, location_name: "Portland, Oregon")
      expect(result.location_name).to eq("Portland, Oregon")
    end

    it "initializes with units" do
      result = ForecastResult.new(forecast: forecast, units: "si")
      expect(result.units).to eq("si")
    end

    it "initializes with an error message" do
      result = ForecastResult.new(error_message: "Something went wrong")
      expect(result.error_message).to eq("Something went wrong")
      expect(result.forecast).to be_nil
    end

    it "initializes with both error and location information" do
      result = ForecastResult.new(
        error_message: "API error",
        location_name: "Portland, OR",
        units: "us"
      )
      expect(result.error_message).to eq("API error")
      expect(result.location_name).to eq("Portland, OR")
      expect(result.units).to eq("us")
      expect(result.forecast).to be_nil
    end
  end

  describe "#error?" do
    it "returns true when error_message is present" do
      result = ForecastResult.new(error_message: "Something went wrong")
      expect(result.error?).to be true
    end

    it "returns false when error_message is nil" do
      result = ForecastResult.new(forecast: forecast)
      expect(result.error?).to be false
    end

    it "returns false when error_message is empty" do
      result = ForecastResult.new(forecast: forecast, error_message: "")
      expect(result.error?).to be false
    end
  end

  describe "serialization compatibility" do
    it "can be serialized and deserialized via Marshal" do
      original = ForecastResult.new(
        forecast: forecast,
        from_cache: true,
        location_name: "Portland, OR",
        units: "us"
      )

      serialized = Marshal.dump(original)
      deserialized = Marshal.load(serialized)

      expect(deserialized).to be_a(ForecastResult)
      expect(deserialized.forecast).to be_a(Forecast)
      expect(deserialized.from_cache).to eq(true)
      expect(deserialized.location_name).to eq("Portland, OR")
      expect(deserialized.units).to eq("us")
    end

    it "can be serialized and deserialized with an error" do
      original = ForecastResult.new(
        error_message: "Something went wrong",
        location_name: "Unknown",
        units: "us"
      )

      serialized = Marshal.dump(original)
      deserialized = Marshal.load(serialized)

      expect(deserialized).to be_a(ForecastResult)
      expect(deserialized.error_message).to eq("Something went wrong")
      expect(deserialized.location_name).to eq("Unknown")
      expect(deserialized.forecast).to be_nil
    end
  end
end
