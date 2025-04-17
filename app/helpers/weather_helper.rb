require_relative '../constants/weather_icon_map'

module WeatherHelper
  def weather_icon_filename(icon_name)
    # Uses centralized mapping from app/constants/weather_icon_map.rb
    WeatherIconMap::ICON_MAP[icon_name] || icon_name
  end
end
