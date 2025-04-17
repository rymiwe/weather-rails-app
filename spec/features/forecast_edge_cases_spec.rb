require 'rails_helper'

RSpec.describe 'Weather Forecast Edge Cases', type: :feature, js: true do
  before(:all) do
    Geocoder.configure(lookup: :test)
  end
  before do
    Geocoder::Lookup::Test.add_stub(
      'Invalid Location', [
        {
          'latitude'     => nil,
          'longitude'    => nil,
          'address'      => nil,
          'city'         => nil,
          'state'        => nil,
          'country'      => nil,
          'country_code' => nil
        }
      ]
    )
  end

  it 'shows error for blank location' do
    visit forecasts_path
    fill_in 'Enter a location', with: ''
    click_button 'Get Forecast'
    expect(page).to have_content("can't be blank").or have_content("must be provided").or have_content("Please enter")
  end

  it 'shows error for invalid location' do
    visit forecasts_path
    fill_in 'Enter a location', with: 'Invalid Location'
    click_button 'Get Forecast'
    expect(page).to have_content('Could not geocode query.')
  end

  it 'rejects malicious input' do
    Geocoder::Lookup::Test.add_stub(
      'New York, NY; DROP TABLE users; --', [
        {
          'latitude'     => nil,
          'longitude'    => nil,
          'address'      => nil,
          'city'         => nil,
          'state'        => nil,
          'country'      => nil,
          'country_code' => nil
        }
      ]
    )
    visit forecasts_path
    fill_in 'Enter a location', with: 'New York, NY; DROP TABLE users; --'
    click_button 'Get Forecast'
    expect(page).not_to have_content('error')
    expect(page).not_to have_content('exception')
    expect(page).not_to have_content('stack trace')
  end
end
