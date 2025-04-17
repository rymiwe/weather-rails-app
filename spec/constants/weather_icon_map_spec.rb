# frozen_string_literal: true

require 'rails_helper'
require 'faraday'
require_relative '../../app/constants/weather_icon_map'

# This spec validates that all weather icon mappings point to real SVGs on the CDN.
# It is slow and makes many external requests, so is excluded from normal runs.
# To run: bundle exec rspec --tag cdn
RSpec.describe WeatherIconMap, :cdn do
  CDN_BASE = 'https://cdn.jsdelivr.net/gh/rickellis/SVG-Weather-Icons@master/Masters-Tempestacons/'.freeze

  around(:example, :cdn) do |example|
    VCR.turn_off!(ignore_cassettes: true)
    example.run
  ensure
    VCR.turn_on!
  end

  CDN_BASE = 'https://cdn.jsdelivr.net/gh/rickellis/SVG-Weather-Icons@master/Masters-Tempestacons/'.freeze

  it 'has a valid SVG file on the CDN for every icon value in ICON_MAP', vcr: false do
    # Allow real HTTP connections for this spec
    WebMock.allow_net_connect!
    missing = []
    WeatherIconMap::ICON_MAP.values.uniq.each do |icon_name|
      response = Faraday.get("#{CDN_BASE}#{icon_name}.svg")
      missing << icon_name unless response.success?
    end
    expect(missing).to be_empty, "Missing icons on CDN: #{missing.join(', ')}"
  ensure
    WebMock.disable_net_connect!(allow_localhost: true)
  end
end
