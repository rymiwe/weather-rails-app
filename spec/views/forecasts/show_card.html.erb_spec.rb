require 'rails_helper'

RSpec.describe "forecasts/_show_card.html.erb", type: :view do
  it "renders the forecast card with summary, icon, and temperatures" do
    assign(:units, 'us')
    forecast = {
      "daily" => { "data" => [ {
        "time" => Time.now.to_i,
        "icon" => "clear-day",
        "temperatureHigh" => 75,
        "temperatureLow" => 64,
        "summary" => "Mostly sunny."
      } ] },
      "currently" => { "temperature" => 70 },
      "timezone" => "America/New_York"
    }
    render partial: "forecasts/show_card", locals: { forecast: forecast, location_name: "Portland, OR", from_cache: false }
    expect(rendered).to include("Today")
    expect(rendered).to include("Mostly sunny")
    expect(rendered).to match(/\d+°F now/)
    expect(rendered).to include("day.svg")
  end

  it "renders gracefully with missing icon" do
    assign(:units, 'us')
    forecast = {
      "daily" => { "data" => [ {
        "time" => Time.now.to_i,
        "temperatureHigh" => 75,
        "temperatureLow" => 64,
        "summary" => "Cloudy."
      } ] },
      "currently" => { "temperature" => 70 },
      "timezone" => "America/New_York"
    }
    render partial: "forecasts/show_card", locals: { forecast: forecast, location_name: "Portland, OR", from_cache: false }
    expect(rendered).to include("Cloudy")
    expect(rendered).not_to include("img") # No icon image
  end

  it "renders gracefully with missing temperature" do
    assign(:units, 'us')
    forecast = {
      "daily" => { "data" => [ {
        "time" => Time.now.to_i,
        "icon" => "clear-day",
        "summary" => "Sunny."
      } ] },
      "timezone" => "America/New_York"
    }
    render partial: "forecasts/show_card", locals: { forecast: forecast, location_name: "Portland, OR", from_cache: false }
    expect(rendered).to include("Sunny")
    expect(rendered).not_to match(/°F now/)
  end

  it "renders SI units correctly" do
    assign(:units, 'si')
    forecast = {
      "daily" => { "data" => [ {
        "time" => Time.now.to_i,
        "icon" => "clear-day",
        "temperatureHigh" => 22,
        "temperatureLow" => 17,
        "summary" => "Partly cloudy."
      } ] },
      "currently" => { "temperature" => 20 },
      "timezone" => "Europe/Paris"
    }
    render partial: "forecasts/show_card", locals: { forecast: forecast, location_name: "Paris, FR", from_cache: false }
    expect(rendered).to include("°C now")
    expect(rendered).to include("Partly cloudy")
  end

  it "renders gracefully with empty summary" do
    assign(:units, 'us')
    forecast = {
      "daily" => { "data" => [ {
        "time" => Time.now.to_i,
        "icon" => "clear-day",
        "temperatureHigh" => 75,
        "temperatureLow" => 64,
        "summary" => ""
      } ] },
      "currently" => { "temperature" => 70 },
      "timezone" => "America/New_York"
    }
    render partial: "forecasts/show_card", locals: { forecast: forecast, location_name: "Portland, OR", from_cache: false }
    expect(rendered).not_to include("..")
  end
end
