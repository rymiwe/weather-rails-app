class ForecastsController < ApplicationController
  cattr_accessor :test_geocoder, :test_weather_client

  def index
    render :index
  end

  def create
    query = params[:query].to_s.strip
    geocoder = self.class.test_geocoder || Geocoder
    weather_client = self.class.test_weather_client || PirateWeatherClient

    @forecast, @from_cache, error_message, @location_name, @units =
      ForecastService.fetch(query, refresh: params[:refresh].present?, geocoder: geocoder, weather_client: weather_client)
    flash[:alert] = error_message if error_message.present?

    respond_to do |format|
      format.turbo_stream { render :create }
      format.html { render :index }
    end
  end

  private
  def forecast_params
    params.permit(:query, :refresh)
  end
end
