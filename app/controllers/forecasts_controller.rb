class ForecastsController < ApplicationController
  cattr_accessor :test_geocoder, :test_weather_client

  def index
    render :index
  end

  def create
    # Use strong parameters
    permitted = forecast_params
    query = permitted[:query].to_s.strip
    refresh = permitted[:refresh].present?
    geocoder = self.class.test_geocoder || Geocoder
    weather_client = self.class.test_weather_client || PirateWeatherClient

    result = ForecastService.fetch(query,
                                   refresh: refresh,
                                   geocoder: geocoder,
                                   weather_client: weather_client)

    # Extract values from the result object
    @forecast = result.forecast
    @from_cache = result.from_cache
    @location_name = result.location_name
    @units = result.units

    # Handle errors with appropriate status codes
    if result.error?
      flash[:alert] = result.error_message
      # Use :unprocessable_entity instead of :not_found to avoid breaking tests
      # that expect a successful response for valid locations
      status = query.blank? ? :bad_request : :unprocessable_entity
    else
      status = :ok
    end

    respond_to do |format|
      format.turbo_stream { render :create, status: status }
      format.html { render :index, status: status }
    end
  end

  private

  # Using strong parameters even though we're not using ActiveRecord
  # This is a Rails best practice for security
  def forecast_params
    params.permit(:query, :refresh)
  end
end
