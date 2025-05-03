require 'rails_helper'

RSpec.describe "Forecasts", type: :feature do
  before(:each) do
    # Clear any remaining cache
    Rails.cache.clear if defined?(Rails.cache) && Rails.cache.respond_to?(:clear)
    
    # Stub the geocoder for consistent test results
    allow_any_instance_of(GeocodingService).to receive(:lookup).with("Portland, OR").and_return({
      lat: 45.5051,
      lon: -122.6750,
      location_name: "Portland, Oregon, USA",
      units: "us"
    })
    
    # Stub return nil for invalid location
    allow_any_instance_of(GeocodingService).to receive(:lookup).with("Invalid Location").and_return(nil)
    
    # Stub the weather client response
    fake_forecast = {
      "currently" => { 
        "temperature" => 68, 
        "summary" => "Partly Cloudy",
        "icon" => "partly-cloudy-day"
      },
      "daily" => {
        "summary" => "Mixed conditions throughout the week.",
        "icon" => "mixed",
        "data" => [
          { 
            "time" => Time.now.to_i,  
            "icon" => "partly-cloudy-day", 
            "temperatureHigh" => 72, 
            "temperatureLow" => 58,
            "summary" => "Partly cloudy throughout the day."
          },
          { 
            "time" => (Time.now + 1.day).to_i, 
            "icon" => "rain", 
            "temperatureHigh" => 65, 
            "temperatureLow" => 55,
            "summary" => "Light rain in the morning."
          },
          { 
            "time" => (Time.now + 2.days).to_i, 
            "icon" => "clear-day", 
            "temperatureHigh" => 78, 
            "temperatureLow" => 62,
            "summary" => "Clear throughout the day."
          }
        ]
      }
    }
    
    allow_any_instance_of(PirateWeatherClient).to receive(:fetch_forecast).and_return(fake_forecast)
  end
  
  describe "search functionality" do
    it "displays forecast when searching for a valid location" do
      visit root_path
      
      # Enter a location and submit the form
      fill_in "query", with: "Portland, OR"
      click_button "Get Forecast"
      
      # Verify the forecast is displayed
      expect(page).to have_content("Portland, Oregon, USA")
      expect(page).to have_content("68°F now")
      expect(page).to have_content("Partly cloudy throughout the day")
    end
    
    it "shows 3-day forecast with high/low temperatures" do
      visit root_path
      
      # Enter a location and submit the form
      fill_in "query", with: "Portland, OR"
      click_button "Get Forecast"
      
      # Verify the 3-day forecast is displayed
      expect(page).to have_content("3-Day Forecast")
      expect(page).to have_content("72°F")  # High temp for today
      expect(page).to have_content("58°F")  # Low temp for today
      expect(page).to have_content("Clear throughout the day")  # Summary for day 3
    end
    
    it "shows an error message for blank queries" do
      visit root_path
      
      # Submit the form without entering a location
      fill_in "query", with: ""
      click_button "Get Forecast"
      
      # Verify error message appears
      expect(page).to have_content("Please enter a query")
    end
    
    it "shows appropriate messages for invalid locations" do
      visit root_path
      
      # Enter an invalid location and submit the form
      fill_in "query", with: "Invalid Location"
      click_button "Get Forecast"
      
      # Verify error message appears
      expect(page).to have_content("Could not geocode query")
    end
  end
  
  describe "basic forecast features" do
    it "shows the 3-day forecast information" do
      visit root_path
      fill_in "query", with: "Portland, OR"
      click_button "Get Forecast"
      
      # Verify the forecast is displayed with 3-day information
      expect(page).to have_content("3-Day Forecast")
      
      # Check for specific temperature data
      expect(page).to have_content("72°F")
      expect(page).to have_content("58°F")
      
      # Check for weather summary data
      expect(page).to have_content("Partly cloudy throughout the day")
      expect(page).to have_content("Light rain in the morning")
      expect(page).to have_content("Clear throughout the day")
    end
  end
  
  # Separate test file that tests caching would be more appropriate,
  # but for now we'll focus on the basic forecast UI tests
end
