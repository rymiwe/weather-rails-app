require 'rails_helper'

RSpec.describe "forecasts/index.html.erb", type: :view do
  it "renders the index view without error" do
    assign(:forecast, Forecast.new(
      temperature: 70,
      summary: "Mostly sunny.",
      icon: "clear-day",
      units: "us",
      location: "Portland, OR",
      raw_data: {"currently" => {"temperature" => 70}, "daily" => {"data" => [{"time" => Time.now.to_i, "icon" => "clear-day", "temperatureHigh" => 75, "temperatureLow" => 64, "summary" => "Mostly sunny."}]}, "timezone" => "America/New_York"}
    ))
    render
    expect(rendered).to be_present
    expect(rendered).to include("Weather Forecast")
    expect(rendered).to include("Get Forecast")
  end
end
