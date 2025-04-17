# frozen_string_literal: true

require 'rails_helper'
require 'ostruct'

# We use dependency injection and explicit Geocoder mocking in this feature spec.
# This avoids reliance on global Geocoder configuration, VCR, or HTTP stubs,
# and ensures robust, isolated, and deterministic tests regardless of Capybara/JS process forking.
# See the comments in the spec for more details.

RSpec.describe 'Weather Forecast', type: :feature, js: true do
  it 'shows a forecast for Portland, OR and updates for New York, NY' do
    # Set up a mock Geocoder
    mock_geocoder = double('Geocoder')
    allow(mock_geocoder).to receive(:search).with('Portland, OR').and_return([
      OpenStruct.new(
        coordinates: [ 45.5231, -122.6765 ],
        country_code: 'US',
        city: 'Portland',
        state: 'Oregon',
        country: 'United States',
        data: {}
      )
    ])
    allow(mock_geocoder).to receive(:search).with('New York, NY').and_return([
      OpenStruct.new(
        coordinates: [ 40.7128, -74.0060 ],
        country_code: 'US',
        city: 'New York',
        state: 'New York',
        country: 'United States',
        data: {}
      )
    ])

    # Inject the mock geocoder into ForecastService via controller (if controller supports it)
    # If not, you may need to stub ForecastService.fetch to always use this mock_geocoder.
    allow(ForecastService).to receive(:fetch).and_wrap_original do |m, *args, **kwargs|
      kwargs[:geocoder] = mock_geocoder
      m.call(*args, **kwargs)
    end

    # Stub PirateWeatherClient to always return a fake forecast
    allow_any_instance_of(PirateWeatherClient).to receive(:fetch_forecast).and_return({
      "currently" => { "temperature" => 60 },
      "daily" => {
        "summary" => "Sunny",
        "icon" => "clear-day",
        "data" => [
          { "icon" => "clear-day", "temperatureHigh" => 75, "temperatureLow" => 55 }
        ]
      }
    })

    visit forecasts_path
    expect(page).to have_selector('#forecast-result')

    fill_in 'Enter a location', with: 'Portland, OR'
    click_button 'Get Forecast'
    expect(page).to have_content('Portland')
    expect(page).to have_content('Weather Forecast')
    expect(page).to have_content('Powered by Pirate Weather')

    fill_in 'Enter a location', with: 'New York, NY'
    click_button 'Get Forecast'
    expect(page).to have_content('New York')
    expect(page).to have_content('Powered by Pirate Weather')
  end
end
