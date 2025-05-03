# This application doesn't use ActiveRecord or a relational database.
# Instead, it uses Redis (a NoSQL key-value database) for caching weather data.
# No ActiveRecord models are needed as the application deals with value objects.

# However, Rails expects ApplicationRecord to exist, so we define it as a bare-bones class
class ApplicationRecord
  # This is a placeholder class to satisfy Rails' expectations
  # It doesn't inherit from ActiveRecord::Base since we're not using ActiveRecord

  # Mimicking some basic ActiveRecord-like behavior for compatibility
  def self.establish_connection(*args)
    # No-op method to prevent errors when Rails tries to establish database connections
  end
end
