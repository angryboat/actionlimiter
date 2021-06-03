# frozen_string_literal: true

require 'action_limiter/instrumentation'
require 'action_limiter/redis'
require 'action_limiter/scripts'

module ActionLimiter
  ##
  # Implementes a Token Bucket algorithm for rate limiting.
  #
  # @author Maddie Schipper
  # @since 0.1.0
  class TokenBucket
    Bucket = Struct.new(:name, :value)

    ##
    # The period length for the bucket in seconds
    #
    # @return [Integer] The specified period
    attr_reader :period

    ##
    # The allowed size of the bucket
    #
    # @return [Integer] The size of the bucket
    attr_reader :size

    ##
    # The bucket namespace. The value will be prefixed to any bucket's name
    #
    # @return [String] The prefix
    attr_reader :namespace

    ##
    # Initialize the token bucket instance
    #
    # @param period [#to_i] The value used to determine the bucket's period
    # @param size [#to_i] The maximum number of tokens in the bucket for the given period
    # @param namespace [nil, #to_s] Value to prefix all
    def initialize(period:, size:, namespace: nil)
      @period = period.to_i
      @size = size.to_i
      @namespace = namespace&.to_s || 'action_limiter/token_bucket'
      @script_hash = ActionLimiter.connection_pool.with do |connection|
        connection.script(:load, ActionLimiter::SCRIPTS.fetch(:token_bucket))
      end
    end

    ##
    # Predicate for checking if the specified bucket name is incremented
    #
    # @param bucket [String] The name of the bucket to check
    # @param time [Time] The time the check will occur
    #
    # @return [true, false] The limiting status of the bucket
    def limited?(bucket, time: Time.now)
      increment(bucket, time).value > size
    end

    ##
    # @private
    def increment(bucket, time)
      ActionLimiter.instrument('action_limiter.token_bucket.increment') do
        ActionLimiter.connection_pool.with do |connection|
          time_stamp = time.to_f
          bucket_key = "#{namespace}/#{bucket}"
          value = connection.evalsha(@script_hash, [bucket_key], [period.to_s, time_stamp.to_s])
          Bucket.new(bucket, value)
        end
      end
    end
  end
end
