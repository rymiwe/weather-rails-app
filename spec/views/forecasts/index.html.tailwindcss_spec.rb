require 'rails_helper'

RSpec.describe "forecasts/index.html.erb", type: :view do
  it "renders the index view without error" do
    assign(:forecast, {})
    render
    expect(rendered).to be_present
    expect(rendered).to include("Weather Forecast")
    expect(rendered).to include("Get Forecast")
  end
end
