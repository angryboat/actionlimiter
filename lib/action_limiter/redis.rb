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
    @connection_pool ||= ConnectionPool.new(size: ENV.fetch('ACTION_LIMITER_POOL_SIZE', 5).to_i) do
      ActionLimiter.create_redis_connection
    end
  end

  ##
  # Create a raw Redis connection
  #
  # @private
  def self.create_redis_connection
    Redis.new(
      host: ENV.fetch('ACTION_LIMITER_REDIS_HOST', '127.0.0.1'),
      port: ENV.fetch('ACTION_LIMITER_REDIS_PORT', 6379).to_i,
      db: ENV.fetch('ACTION_LIMITER_REDIS_DB', 0).to_i
    )
  end
end
