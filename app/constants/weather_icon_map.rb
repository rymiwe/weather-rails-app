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
    "sleet" => "mixed-rain-snow",
    "wind" => "wind",
    "fog" => "fog",
    "thunderstorm" => "thunderstorms",
    "hail" => "hail",
    "mixed" => "mixed-rain-snow",
    "none" => "day",
    # Expanded
    "mostly-clear-day" => "day",
    "mostly-clear-night" => "night",
    "mostly-cloudy-day" => "day-cloudy",
    "mostly-cloudy-night" => "night-cloudy",
    "possible-rain-day" => "day-rain",
    "possible-rain-night" => "night-rain",
    "possible-snow-day" => "day-snow",
    "possible-snow-night" => "night-snow",
    "possible-sleet-day" => "mixed-rain-snow",
    "possible-sleet-night" => "mixed-rain-snow",
    "possible-precipitation-day" => "day-rain",
    "possible-precipitation-night" => "night-rain",
    "precipitation" => "rain",
    "drizzle" => "light-rain",
    "light-rain" => "light-rain",
    "heavy-rain" => "rain",
    "flurries" => "snowshowers",
    "light-snow" => "light-snow",
    "heavy-snow" => "blowing-snow",
    "very-light-sleet" => "mixed-rain-snow",
    "light-sleet" => "mixed-rain-snow",
    "heavy-sleet" => "mixed-rain-snow",
    "breezy" => "wind",
    "dangerous-wind" => "wind"
  }.freeze
end
