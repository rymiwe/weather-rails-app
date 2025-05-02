# Helper for Redis cache testing
module RedisTestHelper
  # Clear the Rails cache before running tests
  def clear_test_cache
    Rails.cache.clear if defined?(Rails.cache)
  end

  # Verify Redis is working correctly
  def verify_redis_working
    return unless defined?(Rails.cache) && Rails.cache.is_a?(ActiveSupport::Cache::RedisCacheStore)

    test_key = "redis_test:#{Time.now.to_i}"
    test_value = "#{SecureRandom.hex(4)}"

    # Test that we can write and read from Redis
    Rails.cache.write(test_key, test_value)
    result = Rails.cache.read(test_key)

    raise "Redis cache is not working properly!" unless result == test_value

    # Clean up test key
    Rails.cache.delete(test_key)
  end
end

RSpec.configure do |config|
  # Include the helper in all specs
  config.include RedisTestHelper

  # Verify Redis is working before the test suite runs
  config.before(:suite) do
    # Create an instance to access the helper methods
    helper = Class.new { include RedisTestHelper }.new
    helper.verify_redis_working
  end

  # Clear cache before each test
  config.before(:each) do
    clear_test_cache
  end
end
