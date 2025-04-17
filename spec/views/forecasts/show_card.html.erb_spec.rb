require 'rails_helper'

RSpec.describe "forecasts/_show_card.html.erb", type: :view do
  it "renders the forecast card with summary, icon, and temperatures" do
    assign(:units, 'us')
    forecast = {
      "daily" => { "data" => [{
        "time" => Time.now.to_i,
        "icon" => "clear-day",
        "temperatureHigh" => 75,
        "temperatureLow" => 64,
        "summary" => "Mostly sunny."
      }] },
      "currently" => { "temperature" => 70 },
      "timezone" => "America/New_York"
    }
    render partial: "forecasts/show_card", locals: { forecast: forecast, location_name: "Portland, OR", from_cache: false }
    expect(rendered).to include("Today")
    expect(rendered).to include("Mostly sunny")
    expect(rendered).to match(/\d+°F now/)
    expect(rendered).to include("day.svg")
  end
end
