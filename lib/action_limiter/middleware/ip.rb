# frozen_string_literal: true

require 'action_limiter/token_bucket'
require 'digest'

module ActionLimiter
  module Middleware
    ##
    # IP based rate limiting middleware
    class IP
      ##
      # @private
      MUTEX = Mutex.new

      ##
      # @private
      def self.period(period = nil)
        MUTEX.synchronize do
          @period = period unless period.nil?
          @period || 1
        end
      end

      ##
      # @private
      def self.bucket_size(bucket_size = nil)
        MUTEX.synchronize do
          @bucket_size = bucket_size unless bucket_size.nil?
          @bucket_size || 100
        end
      end

      ##
      # @private
      def initialize(app)
        @app = app
        @token_bucket = ActionLimiter::TokenBucket.new(
          period: self.class.period,
          size: self.class.bucket_size,
          namespace: 'action_limiter/middleware/ip'
        )
      end

      ##
      # @private
      def call(env)
        request_ip = Digest::MD5.hexdigest(env.ip)

        if @token_bucket.limited?(request_ip)
          rate_limited_response
        else
          @app.call(env)
        end
      end

      private

      def rate_limited_response
        [429, {}, {}]
      end
    end
  end
end
