module ForecastsHelper
  def weather_icon_filename(icon_name)
    aliases = {
      "clear-day" => "day",
      "clear-night" => "night"
    }
    aliases[icon_name] || icon_name
  end
end
