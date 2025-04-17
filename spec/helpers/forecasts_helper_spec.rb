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
  it "returns mapped icon filename for known icon" do
    expect(helper.weather_icon_filename("clear-day")).to eq("day")
  end

  it "returns original icon name if not mapped" do
    expect(helper.weather_icon_filename("unknown-icon")).to eq("unknown-icon")
  end
end
