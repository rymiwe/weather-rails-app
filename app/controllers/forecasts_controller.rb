class ForecastsController < ApplicationController
  def index
    render :index
  end


  def create
    query = params[:query].to_s.strip
    @forecast, @from_cache, error_message, @location_name = WeatherService.fetch(query, refresh: params[:refresh].present?)
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
