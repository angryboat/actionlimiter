# frozen_string_literal: true

require 'connection_pool'
require 'redis'

##
# @private
module ActionLimiter
  ##
  # The shared Redis connection pool
  #
  # @private
  def self.connection_pool
    @connection_pool ||= create_connection_pool
  end

  def self.connection_provider=(connection_provider)
    @connection_provider = connection_provider
  end

  ##
  # @private
  def self.create_connection_pool
    pool_size = ENV.fetch('ACTION_LIMITER_POOL_SIZE', 5).to_i
    timeout = ENV.fetch('ACTION_LIMITER_TIMEOUT', 30).to_i

    ConnectionPool.new(size: pool_size, timeout: timeout) do
      ActionLimiter.create_redis_connection
    end
  end

  ##
  # Create a raw Redis connection
  #
  # @private
  def self.create_redis_connection
    if @connection_provider.respond_to?(:call)
      @connection_provider.call
    else
      Redis.new(
        host: ENV.fetch('ACTION_LIMITER_REDIS_HOST', '127.0.0.1'),
        port: ENV.fetch('ACTION_LIMITER_REDIS_PORT', 6379).to_i,
        db: ENV.fetch('ACTION_LIMITER_REDIS_DB', 0).to_i
      )
    end
  end
end
