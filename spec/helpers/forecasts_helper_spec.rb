require 'rails_helper'

# Specs in this file have access to a helper object that includes
# the WeatherHelper. For example:
#
# describe WeatherHelper do
#   describe "string concat" do
#     it "concats two strings with spaces" do
#       expect(helper.concat_strings("this","that")).to eq("this that")
#     end
#   end
# end
RSpec.describe ForecastsHelper, type: :helper do
  describe "#weather_icon_filename" do
    it "returns mapped icon filename for all known icons" do
      known_icons = {
        "clear-day" => "day",
        "clear-night" => "night",
        "rain" => "rain",
        "snow" => "snow",
        "sleet" => "mixed-rain-snow",
        "wind" => "wind",
        "fog" => "fog",
        "cloudy" => "cloudy",
        "partly-cloudy-day" => "day-cloudy",
        "partly-cloudy-night" => "night-cloudy"
      }
      known_icons.each do |icon, mapped|
        expect(helper.weather_icon_filename(icon)).to eq(mapped)
      end
    end

    it "returns original icon name if not mapped" do
      expect(helper.weather_icon_filename("unknown-icon")).to eq("unknown-icon")
    end

    it "returns nil if icon_name is nil" do
      expect(helper.weather_icon_filename(nil)).to be_nil
    end

    it "returns string if icon_name is integer" do
      expect(helper.weather_icon_filename(123)).to eq(123)
    end

    it "returns stringified integer if icon_name is stringified integer" do
      expect(helper.weather_icon_filename("123")).to eq("123")
    end

    it "returns input if icon_name is a symbol, array, or hash" do
      expect(helper.weather_icon_filename(:clear_day)).to eq(:clear_day)
      expect(helper.weather_icon_filename([ "clear-day" ])) .to eq([ "clear-day" ])
      expect(helper.weather_icon_filename({ icon: "clear-day" })).to eq({ icon: "clear-day" })
    end
  end
  
  describe "#format_temperature" do
    it "formats temperature with Fahrenheit for US units" do
      expect(helper.format_temperature(72.5, "us")).to eq("73°F")
    end
    
    it "formats temperature with Celsius for SI units" do
      expect(helper.format_temperature(22.5, "si")).to eq("23°C")
    end
    
    it "returns placeholder for nil temperature" do
      expect(helper.format_temperature(nil, "us")).to eq("--")
    end
    
    it "rounds temperature values to nearest integer" do
      expect(helper.format_temperature(72.1, "us")).to eq("72°F")
      expect(helper.format_temperature(72.9, "us")).to eq("73°F")
    end
  end
  
  describe "#weather_condition_classes" do
    it "returns a string with base styling classes" do
      classes = helper.weather_condition_classes("Clear")
      expect(classes).to include("p-2 rounded-lg")
    end
    
    it "returns empty string for nil or empty summary" do
      expect(helper.weather_condition_classes(nil)).to eq("")
      expect(helper.weather_condition_classes("")).to eq("")
    end
    
    it "applies consistent styling to all weather conditions" do
      conditions = ["Rain", "Clear", "Partly Cloudy", "Snow", "Thunderstorm"]
      expected_class = "p-2 rounded-lg bg-blue-100 text-blue-800"
      
      conditions.each do |condition|
        expect(helper.weather_condition_classes(condition)).to eq(expected_class)
      end
    end
  end
  
  describe "#cache_status" do
    it "returns cached indicator when forecast is from cache" do
      result = helper.cache_status(true)
      expect(result).to include("Cached")
      expect(result).to include("text-gray-500")
    end
    
    it "returns live indicator when forecast is not from cache" do
      result = helper.cache_status(false)
      expect(result).to include("Live")
      expect(result).to include("text-green-600")
    end
  end
  
  describe "#format_location" do
    it "formats valid location names" do
      expect(helper.format_location("Portland, OR")).to eq("Portland, OR")
    end
    
    it "returns fallback text for blank location" do
      expect(helper.format_location(nil)).to eq("Unknown Location")
      expect(helper.format_location("")).to eq("Unknown Location")
      expect(helper.format_location(" ")).to eq("Unknown Location")
    end
  end
end
