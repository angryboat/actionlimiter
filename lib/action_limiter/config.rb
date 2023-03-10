# frozen_string_literal: true

require 'redis-client'
require 'singleton'

module ActionLimiter # rubocop:disable Style/Documentation
  ##
  # This module provides a configuration class for the `ActionLimiter` gem.
  #
  # The `Config` class is a singleton that provides configuration for the gem's Redis connection pool.
  #
  # @since 1.0
  class Config
    include Singleton

    ##
    # @private
    def initialize
      @monitor = Monitor.new

      @redis_config = RedisClient.config(host: 'localhost', port: 6379, db: 0)
      @pool_timeout = 1.0
      @pool_size = Integer(ENV.fetch('RAILS_MAX_THREADS', 5))
    end

    ##
    # Sets the pool timeout for the Redis connection pool.
    #
    # @param timeout [Numeric] the new pool timeout value, in seconds.
    def pool_timeout=(pool_timeout)
      @monitor.synchronize do
        @pool_timeout = Float(pool_timeout)
        unsafe_rebuild_connection_pool
      end
    end

    ##
    # Sets the pool size for the Redis connection pool.
    #
    # @param size [Integer] the new pool size value.
    def pool_size=(_pool_size)
      @monitor.synchronize do
        @pool_size = Integer(pool_timeout)
        unsafe_rebuild_connection_pool
      end
    end

    ##
    # Sets the Redis configuration for the connection pool.
    #
    # @param redis_config [RedisClient::Config] the new Redis configuration.
    #
    # @return [RedisClient::Config] the new Redis configuration.
    def redis_config=(redis_config)
      @monitor.synchronize do
        @redis_config = redis_config
        unsafe_rebuild_connection_pool
      end
    end

    def connection_pool
      @monitor.synchronize do
        @connection_pool ||= @redis_config.new_pool(
          timeout: @pool_timeout,
          size: @pool_size
        )
      end
    end

    private

    def unsafe_rebuild_connection_pool
      @connection_pool&.shutdown(&:close)
      @connection_pool = nil
    end
  end

  def self.redis(&)
    if block_given?
      Config.instance.connection_pool.with(&)
    else
      Config.instance.connection_pool
    end
  end
end
