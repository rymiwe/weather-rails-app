module ForecastsHelper
  def weather_icon_filename(icon_name)
    aliases = {
      # Standard
      "clear-day" => "day",
      "clear-night" => "night",
      "partly-cloudy-day" => "day-cloudy",
      "partly-cloudy-night" => "night-cloudy",
      "cloudy-day" => "day-cloudy",
      "cloudy-night" => "night-cloudy",
      "rain" => "rain",
      "snow" => "snow",
      "sleet" => "sleet",
      "wind" => "wind",
      "fog" => "fog",
      "thunderstorm" => "thunderstorm",
      "hail" => "hail",
      "mixed" => "precipitation",
      "none" => "none",
      # Expanded
      "mostly-clear-day" => "day",
      "mostly-clear-night" => "night",
      "mostly-cloudy-day" => "day-cloudy",
      "mostly-cloudy-night" => "night-cloudy",
      "possible-rain-day" => "rain",
      "possible-rain-night" => "rain",
      "possible-snow-day" => "snow",
      "possible-snow-night" => "snow",
      "possible-sleet-day" => "sleet",
      "possible-sleet-night" => "sleet",
      "possible-precipitation-day" => "precipitation",
      "possible-precipitation-night" => "precipitation",
      "precipitation" => "precipitation",
      "drizzle" => "drizzle",
      "light-rain" => "light-rain",
      "heavy-rain" => "heavy-rain",
      "flurries" => "flurries",
      "light-snow" => "light-snow",
      "heavy-snow" => "heavy-snow",
      "very-light-sleet" => "light-sleet",
      "light-sleet" => "light-sleet",
      "heavy-sleet" => "heavy-sleet",
      "breezy" => "breezy",
      "dangerous-wind" => "dangerous-wind"
    }
    aliases[icon_name] || icon_name
  end
end
