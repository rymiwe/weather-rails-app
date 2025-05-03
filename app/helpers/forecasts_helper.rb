module ForecastsHelper
  def weather_icon_filename(icon_name)
    # Uses centralized mapping from app/constants/weather_icon_map.rb
    WeatherIconMap::ICON_MAP[icon_name] || icon_name
  end

  # Format temperature with the correct unit symbol
  def format_temperature(temp, units)
    return "--" if temp.nil?

    symbol = units == "us" ? "°F" : "°C"
    "#{temp.round}#{symbol}"
  end

  # Returns appropriate CSS classes for weather conditions
  def weather_condition_classes(summary)
    return "" unless summary.present?

    # Using consistent styling for all weather conditions
    "p-2 rounded-lg bg-blue-100 text-blue-800"
  end

  # Format cache status for display
  def cache_status(from_cache)
    if from_cache
      content_tag(:span, "CACHED", class: "text-xs font-semibold bg-blue-100 text-blue-800 rounded px-2 py-1")
    else
      content_tag(:span, "LIVE", class: "text-xs font-semibold bg-green-100 text-green-800 rounded px-2 py-1")
    end
  end

  # Format location information consistently
  def format_location(location)
    return "Unknown Location" if location.blank?
    location
  end
end
