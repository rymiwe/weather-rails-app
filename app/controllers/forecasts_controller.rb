class ForecastsController < ApplicationController
  cattr_accessor :test_geocoder, :test_weather_client

  def index
    render :index
  end

  def create
    query = params[:query].to_s.strip
    geocoder = self.class.test_geocoder || Geocoder
    weather_client = self.class.test_weather_client || PirateWeatherClient

    result = ForecastService.fetch(query,
                                   refresh: params[:refresh].present?,
                                   geocoder: geocoder,
                                   weather_client: weather_client)

    # Extract values from the result object
    @forecast = result.forecast
    @from_cache = result.from_cache
    @location_name = result.location_name
    @units = result.units
    flash[:alert] = result.error_message if result.error?

    respond_to do |format|
      format.turbo_stream { render :create }
      format.html { render :index }
    end
  end
end
