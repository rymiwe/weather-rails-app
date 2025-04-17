module ApplicationHelper
  def format_temperature(value, units)
    return "" if value.blank?
    unit_symbol = units == "si" ? "°C" : "°F"
    "#{value.round}#{unit_symbol}"
  end
end
