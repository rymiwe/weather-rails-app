class ForecastsController < ApplicationController
  def index
    # Show search form
  end


  def create
    address = params[:address].to_s.strip
    @forecast, @from_cache, error_message, @location_name = ForecastService.fetch(address, refresh: params[:refresh].present?)
    flash[:alert] = error_message if error_message.present?

    respond_to do |format|
      format.turbo_stream { render :create }
      format.html { render :index }
    end
  end

  private
  def forecast_params
    params.permit(:address, :refresh)
  end
end
