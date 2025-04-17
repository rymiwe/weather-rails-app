# frozen_string_literal: true
require 'rails_helper'
require 'net/http'
require_relative '../../app/constants/weather_icon_map'

# This spec validates that all weather icon mappings point to real SVGs on the CDN.
# It is slow and makes many external requests, so is excluded from normal runs.
# To run: bundle exec rspec --tag cdn
RSpec.describe WeatherIconMap, :cdn do
  CDN_BASE = 'https://cdn.jsdelivr.net/gh/rickellis/SVG-Weather-Icons@master/Masters-Tempestacons/'.freeze

  it 'has a valid SVG file on the CDN for every icon value in ICON_MAP' do
    # Completely disable VCR for this spec
    VCR.turn_off!(ignore_cassettes: true)
    WebMock.allow_net_connect!
    missing = []
    WeatherIconMap::ICON_MAP.values.uniq.each do |icon_name|
      url = URI("#{CDN_BASE}#{icon_name}.svg")
      response = Net::HTTP.get_response(url)
      unless response.is_a?(Net::HTTPSuccess)
        missing << icon_name
      end
    end
    expect(missing).to be_empty, "Missing icons on CDN: #{missing.join(', ')}"
  ensure
    VCR.turn_on!
    WebMock.disable_net_connect!(allow_localhost: true)
  end
end
