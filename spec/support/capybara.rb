require 'capybara/rspec'

Capybara.register_driver :headless_chrome do |app|
  options = Selenium::WebDriver::Chrome::Options.new
  options.add_argument('--headless')
  options.add_argument('--disable-gpu')
  options.add_argument('--no-sandbox')
  options.add_argument('--disable-dev-shm-usage')
  options.add_argument('--window-size=1400,1400')
  Capybara::Selenium::Driver.new(app, browser: :chrome, options: options)
end

Capybara.javascript_driver = :headless_chrome

RSpec.configure do |config|
  config.before(:each, type: :feature, js: true) do
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
    # Default stub for any other query
    allow(mock_geocoder).to receive(:search).and_return([])

    ForecastsController.test_geocoder = mock_geocoder
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
  end
  config.after(:each, type: :feature, js: true) do
    ForecastsController.test_geocoder = nil
  end
end
