module ApplicationHelper
  def format_temperature(value, units)
    return "" if value.blank?
    # For Pirate Weather API: "us" = Imperial units (Fahrenheit), "si" = Metric (Celsius)
    # https://pirateweather.net/en/latest/forecast-request/
    unit_symbol = units == "si" ? "°C" : "°F"
    "#{value.round}#{unit_symbol}"
  end
end
