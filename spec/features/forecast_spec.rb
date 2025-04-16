# frozen_string_literal: true
require 'rails_helper'

RSpec.describe 'Weather Forecast', type: :feature, js: true, vcr: { record: :new_episodes } do
  before do
    # Stub geocoder for deterministic results
    Geocoder::Lookup::Test.add_stub(
      'Portland, OR', [
        {
          'latitude'     => 45.5231,
          'longitude'    => -122.6765,
          'address'      => 'Portland, OR, USA',
          'city'         => 'Portland',
          'state'        => 'Oregon',
          'country'      => 'United States',
          'country_code' => 'US'
        }
      ]
    )
    Geocoder::Lookup::Test.add_stub(
      'New York, NY', [
        {
          'latitude'     => 40.7128,
          'longitude'    => -74.0060,
          'address'      => 'New York, NY, USA',
          'city'         => 'New York',
          'state'        => 'New York',
          'country'      => 'United States',
          'country_code' => 'US'
        }
      ]
    )
    Geocoder::Lookup::Test.set_default_stub([
      {
        'latitude'     => 0.0,
        'longitude'    => 0.0,
        'address'      => 'Unknown',
        'city'         => nil,
        'state'        => nil,
        'country'      => nil,
        'country_code' => nil
      }
    ])
  end

  it 'shows a forecast for Portland, OR and updates for New York, NY', :vcr do
    visit forecasts_path
    # On initial load, the turbo-frame should be present
    expect(page).to have_selector('#forecast-result')

    fill_in 'Enter a location', with: 'Portland, OR'
    click_button 'Get Forecast'
    # After Turbo Stream update, only check for forecast content
    expect(page).to have_content('Portland')
    expect(page).to have_content('Weather Forecast')
    expect(page).to have_content('Powered by Pirate Weather')

    fill_in 'Enter a location', with: 'New York, NY'
    click_button 'Get Forecast'
    puts "AFTER SECOND SUBMIT:"
    puts page.body
    expect(page).to have_content('New York')
    expect(page).to have_content('Powered by Pirate Weather')
  end
end
