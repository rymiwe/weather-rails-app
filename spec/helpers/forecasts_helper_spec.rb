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
    expect(helper.weather_icon_filename(["clear-day"])) .to eq(["clear-day"])
    expect(helper.weather_icon_filename({icon: "clear-day"})).to eq({icon: "clear-day"})
  end
end
