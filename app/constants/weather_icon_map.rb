# frozen_string_literal: true

module WeatherIconMap
  ICON_MAP = {
    # Standard
    "clear-day" => "day",
    "clear-night" => "night",
    "partly-cloudy-day" => "day-cloudy",
    "partly-cloudy-night" => "night-cloudy",
    "cloudy-day" => "day-cloudy",
    "cloudy-night" => "night-cloudy",
    "cloudy" => "cloudy",
    "rain" => "rain",
    "snow" => "snow",
    "sleet" => "rain",  # No sleet icon, use rain
    "wind" => "wind",
    "fog" => "fog",
    "thunderstorm" => "rain",  # No thunderstorm icon, use rain
    "hail" => "hail",
    "mixed" => "rain",  # No precipitation icon, use rain
    "none" => "cloudy",  # No 'none' icon, use cloudy
    # Expanded
    "mostly-clear-day" => "day",
    "mostly-clear-night" => "night",
    "mostly-cloudy-day" => "day-cloudy",
    "mostly-cloudy-night" => "night-cloudy",
    "possible-rain-day" => "rain",
    "possible-rain-night" => "rain",
    "possible-snow-day" => "snow",
    "possible-snow-night" => "snow",
    "possible-sleet-day" => "rain",  # No sleet icon, use rain
    "possible-sleet-night" => "rain",  # No sleet icon, use rain
    "possible-precipitation-day" => "rain",  # No precipitation icon, use rain
    "possible-precipitation-night" => "rain",  # No precipitation icon, use rain
    "precipitation" => "rain",  # No precipitation icon, use rain
    "drizzle" => "rain",  # No drizzle icon, use rain
    "light-rain" => "light-rain",
    "heavy-rain" => "rain",  # No heavy-rain icon, use rain
    "flurries" => "snow",  # No flurries icon, use snow
    "light-snow" => "light-snow",
    "heavy-snow" => "snow",  # No heavy-snow icon, use snow
    "very-light-sleet" => "rain",  # No light-sleet icon, use rain
    "light-sleet" => "rain",  # No light-sleet icon, use rain
    "heavy-sleet" => "rain",  # No heavy-sleet icon, use rain
    "breezy" => "wind",  # No breezy icon, use wind
    "dangerous-wind" => "wind"  # No dangerous-wind icon, use wind
  }.freeze
end
