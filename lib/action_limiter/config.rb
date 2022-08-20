# frozen_string_literal: true

require 'connection_pool'
require 'redis'
require 'singleton'

module ActionLimiter # rubocop:disable Style/Documentation
  ##
  # Provides configuration for the Gem
  #
  # @author Maddie Schipper
  # @since 1.0.0
  class Config
    include Singleton

    ##
    # The shared Redis connection pool
    attr_accessor :redis

    ##
    # The URL used for new Redis connections in the default pool
    attr_accessor :redis_url

    ##
    # @private
    def initialize
      pool_size = ENV.fetch('RAILS_MAX_THREADS', 1).to_i

      self.redis_url = 'redis://localhost:6379/0'
      self.redis = ConnectionPool.new(size: pool_size) do
        Redis.new(url: redis_url)
      end
    end
  end

  ##
  # @private
  def self.with_redis_connection(...)
    Config.instance.redis.with(...)
  end
end
