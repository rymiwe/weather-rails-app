require 'rails_helper'

RSpec.describe "forecasts/_show_card.html.erb", type: :view do
  let(:forecast) {
    Forecast.new(
      temperature: 70,
      summary: "Mostly sunny.",
      icon: "clear-day",
      units: "us",
      location: "Portland, OR",
      raw_data: { "currently" => { "temperature" => 70 }, "daily" => { "data" => [ { "time" => Time.now.to_i, "icon" => "clear-day", "temperatureHigh" => 75, "temperatureLow" => 64, "summary" => "Mostly sunny." } ] }, "timezone" => "America/New_York" }
    )
  }

  it "renders the forecast card with summary, icon, and temperatures" do
    assign(:units, 'us')
    render partial: "forecasts/show_card", locals: { forecast: forecast, location_name: "Portland, OR", from_cache: false }
    expect(rendered).to include("Today")
    expect(rendered).to include("Mostly sunny")
    expect(rendered).to match(/\d+°F now/)
    expect(rendered).to include("day.svg")
  end

  it "renders gracefully with missing icon" do
    assign(:units, 'us')
    forecast = Forecast.new(
      temperature: 70,
      summary: "Cloudy.",
      icon: nil,
      units: "us",
      location: "Portland, OR",
      raw_data: {
        "daily" => { "data" => [ {
          "time" => Time.now.to_i,
          "temperatureHigh" => 75,
          "temperatureLow" => 64,
          "summary" => "Cloudy."
        } ] },
        "currently" => { "temperature" => 70 },
        "timezone" => "America/New_York"
      }
    )
    render partial: "forecasts/show_card", locals: { forecast: forecast, location_name: "Portland, OR", from_cache: false }
    expect(rendered).to include("Cloudy")
    expect(rendered).not_to include("img") # No icon image
  end

  it "renders gracefully with missing temperature" do
    assign(:units, 'us')
    forecast = Forecast.new(
      temperature: nil,
      summary: "Sunny.",
      icon: "clear-day",
      units: "us",
      location: "Portland, OR",
      raw_data: {
        "daily" => { "data" => [ {
          "time" => Time.now.to_i,
          "icon" => "clear-day",
          "summary" => "Sunny."
        } ] },
        "timezone" => "America/New_York"
      }
    )
    render partial: "forecasts/show_card", locals: { forecast: forecast, location_name: "Portland, OR", from_cache: false }
    expect(rendered).to include("Sunny")
    expect(rendered).not_to match(/°F now/)
  end

  it "renders SI units correctly" do
    assign(:units, 'si')
    forecast = Forecast.new(
      temperature: 20,
      summary: "Partly cloudy.",
      icon: "clear-day",
      units: "si",
      location: "Paris, FR",
      raw_data: {
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
    )
    render partial: "forecasts/show_card", locals: { forecast: forecast, location_name: "Paris, FR", from_cache: false }
    expect(rendered).to include("°C now")
    expect(rendered).to include("Partly cloudy")
  end

  it "renders gracefully with empty summary" do
    assign(:units, 'us')
    forecast = Forecast.new(
      temperature: 70,
      summary: "",
      icon: "clear-day",
      units: "us",
      location: "Portland, OR",
      raw_data: {
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
    )
    render partial: "forecasts/show_card", locals: { forecast: forecast, location_name: "Portland, OR", from_cache: false }
    expect(rendered).not_to include("..")
  end

  it "shows cache badge when result is from cache" do
    assign(:units, 'us')
    forecast = Forecast.new(
      temperature: 70,
      summary: "Sunny.",
      icon: "clear-day",
      units: "us",
      location: "Portland, OR",
      raw_data: {
        "daily" => { "data" => [ {
          "time" => Time.now.to_i,
          "icon" => "clear-day",
          "temperatureHigh" => 75,
          "temperatureLow" => 64,
          "summary" => "Sunny."
        } ] },
        "currently" => { "temperature" => 70 },
        "timezone" => "America/New_York",
        "cached_at" => Time.current.iso8601
      }
    )

    render partial: "forecasts/show_card", locals: { forecast: forecast, location_name: "Portland, OR", from_cache: true }
    expect(rendered).to include("Cached")
    expect(rendered).to include("expires in")
  end

  it "hides cache badge when result is not from cache" do
    assign(:units, 'us')
    forecast = Forecast.new(
      temperature: 70,
      summary: "Sunny.",
      icon: "clear-day",
      units: "us",
      location: "Portland, OR",
      raw_data: {
        "daily" => { "data" => [ {
          "time" => Time.now.to_i,
          "icon" => "clear-day",
          "temperatureHigh" => 75,
          "temperatureLow" => 64,
          "summary" => "Sunny."
        } ] },
        "currently" => { "temperature" => 70 },
        "timezone" => "America/New_York"
      }
    )

    render partial: "forecasts/show_card", locals: { forecast: forecast, location_name: "Portland, OR", from_cache: false }
    expect(rendered).not_to include("Cached")
  end
end
