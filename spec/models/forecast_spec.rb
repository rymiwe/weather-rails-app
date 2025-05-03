require 'rails_helper'

RSpec.describe Forecast do
  describe "#initialize" do
    it "initializes with all required attributes" do
      forecast = Forecast.new(
        temperature: 72.5,
        summary: "Partly Cloudy",
        icon: "partly-cloudy-day",
        units: "us",
        location: "Seattle, WA"
      )
      
      expect(forecast.temperature).to eq(72.5)
      expect(forecast.summary).to eq("Partly Cloudy")
      expect(forecast.icon).to eq("partly-cloudy-day")
      expect(forecast.units).to eq("us")
      expect(forecast.location).to eq("Seattle, WA")
      expect(forecast.raw_data).to be_nil
    end
    
    it "initializes with optional raw_data" do
      raw_data = { "currently" => { "temperature" => 72.5 } }
      forecast = Forecast.new(
        temperature: 72.5,
        summary: "Partly Cloudy",
        icon: "partly-cloudy-day",
        units: "us",
        location: "Seattle, WA",
        raw_data: raw_data
      )
      
      expect(forecast.raw_data).to eq(raw_data)
    end
  end
  
  describe "temperature unit methods" do
    it "#fahrenheit? returns true for US units" do
      forecast = Forecast.new(
        temperature: 72,
        summary: "Sunny",
        icon: "clear-day",
        units: "us",
        location: "Portland, OR"
      )
      
      expect(forecast.fahrenheit?).to be true
      expect(forecast.celsius?).to be false
    end
    
    it "#celsius? returns true for SI units" do
      forecast = Forecast.new(
        temperature: 22,
        summary: "Sunny",
        icon: "clear-day",
        units: "si",
        location: "London, UK"
      )
      
      expect(forecast.celsius?).to be true
      expect(forecast.fahrenheit?).to be false
    end
  end
  
  describe "serialization" do
    it "can be serialized and deserialized via Marshal" do
      raw_data = { "currently" => { "temperature" => 72.5 } }
      original = Forecast.new(
        temperature: 72.5,
        summary: "Partly Cloudy",
        icon: "partly-cloudy-day",
        units: "us",
        location: "Seattle, WA",
        raw_data: raw_data
      )
      
      serialized = Marshal.dump(original)
      deserialized = Marshal.load(serialized)
      
      expect(deserialized).to be_a(Forecast)
      expect(deserialized.temperature).to eq(72.5)
      expect(deserialized.summary).to eq("Partly Cloudy")
      expect(deserialized.icon).to eq("partly-cloudy-day")
      expect(deserialized.units).to eq("us")
      expect(deserialized.location).to eq("Seattle, WA")
      expect(deserialized.raw_data).to eq(raw_data)
    end
  end
  
  if defined?(GlobalID)
    describe "GlobalID compatibility" do
      it "includes GlobalID::Identification if available" do
        expect(Forecast.included_modules).to include(GlobalID::Identification)
      end
    end
  end
end
