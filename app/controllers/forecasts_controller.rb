class ForecastsController < ApplicationController
  def index
    # Show search form
  end


  def create
    address = params[:address].to_s.strip
    if address.blank?
      flash[:alert] = 'Please enter an address.'
      return redirect_to forecasts_path
    end

    geo_result = Geocoder.search(address).first
    Rails.logger.info("Geocoder result for '#{address}': #{geo_result.inspect}")
    coords = geo_result&.coordinates

    # Extract city, state, country for display
    if geo_result
      city = geo_result.city || geo_result.data["city"] || geo_result.data["town"] || geo_result.data["village"]
      state = geo_result.state || geo_result.data["state"]
      country = geo_result.country || geo_result.data["country"]
      parts = [city, state, country].compact
      @location_name = parts.join(", ") if parts.any?
    end
    unless coords
      flash[:alert] = 'Could not geocode address.'
      respond_to do |format|
        format.turbo_stream { render turbo_stream: turbo_stream.replace('forecast-result', partial: 'shared/flash', locals: { flash: flash }) }
        format.html { redirect_to forecasts_path }
      end
      return
    end
    lat, lon = coords.map { |c| c.round(4) }

    forecast = Forecast.where(latitude: lat, longitude: lon).order(cached_at: :desc).first
    cache_expiry = 30.minutes.ago
    if forecast && forecast.cached_at > cache_expiry && params[:refresh].blank?
      @forecast = forecast
      @from_cache = true
    else
      api_key = Rails.application.credentials.dig(:weather, :pirate_api_key)
      if api_key.blank?
        flash[:alert] = 'Pirate Weather API key missing. Please check credentials.'
        respond_to do |format|
          format.turbo_stream { render turbo_stream: turbo_stream.replace('forecast-result', partial: 'shared/flash', locals: { flash: flash }) }
          format.html { redirect_to forecasts_path }
        end
        return
      end
      # Correct Pirate Weather endpoint as of April 2025
      url = "https://api.pirateweather.net/forecast/#{api_key}/#{lat},#{lon}?units=us"
      if Rails.env.development?
        masked_key = api_key.length > 4 ? ("*" * (api_key.length - 4) + api_key[-4..-1]) : api_key
        Rails.logger.info("Pirate Weather request URL: #{url.gsub(api_key, masked_key)}")
        flash[:notice] = "Requesting: #{url.gsub(api_key, masked_key)}"
      end
      begin
        response = HTTP.get(url)
        if response.status.success?
          data = JSON.parse(response.body.to_s)
          @forecast = Forecast.create!(latitude: lat, longitude: lon, data: data, cached_at: Time.current)
          @from_cache = false
        else
          Rails.logger.error("Pirate Weather API failure: status=#{response.status}, body=#{response.body}")
          short_error = "Pirate Weather API error. Status: #{response.status}. See Rails logs for details."
          flash[:alert] = short_error
          respond_to do |format|
            format.turbo_stream { render turbo_stream: turbo_stream.replace('forecast-result', partial: 'shared/flash', locals: { flash: flash }) }
            format.html { redirect_to forecasts_path }
          end
          return
        end
      rescue => e
        Rails.logger.error("Pirate Weather fetch error: #{e}")
        flash[:alert] = 'Error fetching weather data.'
        respond_to do |format|
          format.turbo_stream { render turbo_stream: turbo_stream.replace('forecast-result', partial: 'shared/flash', locals: { flash: flash }) }
          format.html { redirect_to forecasts_path }
        end
        return
      end
    end

    respond_to do |format|
      format.turbo_stream { render turbo_stream: turbo_stream.replace('forecast-result', partial: 'forecasts/show_card', locals: { forecast: @forecast, location_name: @location_name, from_cache: @from_cache }) }
      format.html { render :index }
    end
  end

  private
  def forecast_params
    params.permit(:address, :refresh)
  end
end
