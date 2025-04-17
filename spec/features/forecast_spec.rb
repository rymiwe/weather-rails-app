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
    
    # Create a mock forecast response
    forecast_data = {
      "currently" => {"summary" => "Clear", "temperature" => 60},
      "daily" => {
        "summary" => "Sunny", 
        "icon" => "clear-day", 
        "data" => [{
          "icon" => "clear-day", 
          "temperatureHigh" => 70, 
          "temperatureLow" => 50
        }]
      }
    }
    
    # Create and configure a mock weather client
    mock_client = instance_double("PirateWeatherClient")
    allow(mock_client).to receive(:fetch_forecast).and_return(forecast_data)
    allow(PirateWeatherClient).to receive(:new).and_return(mock_client)
    
    # Turn off external HTTP requests for safety
    WebMock.disable_net_connect!(allow_localhost: true)
    visit forecasts_path
    fill_in :query, with: 'Portland, OR'
    click_button 'Get Forecast'
    expect(page).to have_content('Weather Forecast')
    expect(page).to have_content('Portland')
    expect(page).to have_content('Powered by Pirate Weather')
  end
end
