require 'rails_helper'

RSpec.describe ApplicationRecord do
  describe ".establish_connection" do
    it "doesn't raise an error when called" do
      expect { ApplicationRecord.establish_connection }.not_to raise_error
    end

    it "can accept arguments" do
      expect { ApplicationRecord.establish_connection(adapter: "test") }.not_to raise_error
      expect { ApplicationRecord.establish_connection({}) }.not_to raise_error
      expect { ApplicationRecord.establish_connection(nil) }.not_to raise_error
    end
  end

  it "exists as a placeholder class for Rails compatibility" do
    expect(defined?(ApplicationRecord)).to eq("constant")
    expect(ApplicationRecord).to be_a(Class)
  end
end
