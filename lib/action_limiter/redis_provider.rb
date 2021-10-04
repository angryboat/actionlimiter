# frozen_string_literal: true

require 'connection_pool'
require 'redis'

##
# @private
module ActionLimiter
  ##
  # Private
  class RedisProvider
    MUTEX = Mutex.new

    class << self
      def pool_size
        ENV.fetch('ACTION_LIMITER_POOL_SIZE', 5).to_i
      end

      def pool_connection_timeout
        ENV.fetch('ACTION_LIMITER_TIMEOUT', 30).to_i
      end

      def redis_connection_host
        ENV.fetch('ACTION_LIMITER_REDIS_HOST', '127.0.0.1')
      end

      def redis_connection_port
        ENV.fetch('ACTION_LIMITER_REDIS_PORT', 6379).to_i
      end

      def redis_connection_database
        ENV.fetch('ACTION_LIMITER_REDIS_DB', 0).to_i
      end

      def connection_pool
        MUTEX.synchronize do
          @connection_pool ||= unsafe_create_connection_pool
        end
      end

      def unsafe_create_connection_pool
        ConnectionPool.new(size: pool_size, timeout: pool_connection_timeout) do
          RedisProvider.unsafe_create_redis_connection
        end
      end

      def unsafe_create_redis_connection
        Redis.new(
          host: redis_connection_host,
          port: redis_connection_port,
          db: redis_connection_database
        )
      end
    end
  end
end
