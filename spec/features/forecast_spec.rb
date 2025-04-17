require 'rails_helper'

RSpec.describe 'Weather Forecast', type: :feature do
  it 'shows a forecast for a location' do
    # Use Geocoder test stub for 'Portland, OR'
    Geocoder::Lookup::Test.add_stub(
      "Portland, OR", [
        {
          'latitude'     => 45.5152,
          'longitude'    => -122.6784,
          'address'      => 'Portland, OR, USA',
          'city'         => 'Portland',
          'state'        => 'OR',
          'country'      => 'US',
          'country_code' => 'US'
        }
      ]
    )
    # Stub Pirate Weather API for Portland coordinates
    WebMock.stub_request(:get, /pirate-weather-api|pirateweather/).
      to_return(status: 200, body: '{"currently":{"summary":"Clear","temperature":60},"daily":{"summary":"Sunny","icon":"clear-day","data":[{"icon":"clear-day","temperatureHigh":70,"temperatureLow":50}]}}')
    visit forecasts_path
    fill_in :query, with: 'Portland, OR'
    click_button 'Get Forecast'
    expect(page).to have_content('Weather Forecast')
    expect(page).to have_content('Portland')
    expect(page).to have_content('Powered by Pirate Weather')
  end
end
