require 'rails_helper'

RSpec.describe 'Weather Forecast', type: :feature do
  it 'shows a forecast for a location' do
    visit forecasts_path
    fill_in :query, with: 'Portland, OR'
    click_button 'Get Forecast'
    expect(page).to have_content('Weather Forecast')
    expect(page).to have_content('Portland')
    expect(page).to have_content('Powered by Pirate Weather')
  end
end
