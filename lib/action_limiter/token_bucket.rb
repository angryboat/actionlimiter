# frozen_string_literal: true

require 'action_limiter/config'
require 'action_limiter/instrumentation'
require 'action_limiter/scripts'

module ActionLimiter
  ##
  # Implementes a Token Bucket algorithm for rate limiting.
  #
  # @author Maddie Schipper
  # @since 0.1.0
  class TokenBucket
    ##
    # Bucket contains information about a single bucket in a TokenBucket.
    #
    # @attr_reader [String] name A string representing the name of the bucket.
    # @attr_reader [Integer] value An integer representing the current value of the bucket.
    # @attr_reader [Integer] max_size An integer representing the maximum value of the bucket.
    # @attr_reader [Integer] period An integer representing the period (in seconds) for which the bucket should retain its value.
    #
    # @example Checking if a bucket is limited
    #   # Increment the "user:1" bucket and get its value
    #   bucket = ActionLimiter::TokenBucket.new(period: 5, size: 20).increment('user:1').value
    #
    #   # Check if the bucket is limited
    #   if bucket.limited?
    #     # Do something if the bucket is limited
    #   else
    #     # Do something if the bucket is not limited
    #   end
    Bucket = Struct.new(:name, :value, :max_size, :period, keyword_init: true) do
      def limited?
        value > max_size # Not >= because the request that created this bucket incremented the counter
      end
    end

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
    end

    ##
    # Predicate for checking if the specified bucket name is incremented
    #
    # @param bucket [String] The name of the bucket to check
    # @param time [Time] The time the check will occur
    #
    # @return [true, false] The limiting status of the bucket
    def limited?(bucket, time: Time.now)
      increment(bucket, time:).limited?
    end

    # This method is defined in the `ActionLimiter::TokenBucket` class and is
    # used to increment a bucket's value and return it as a `Bucket` struct.
    #
    # @param bucket [String] A string representing the name of the bucket to
    # increment. @param time [Time] (optional) A `Time` object representing the
    #   time of the increment. If not specified, the current time will be used.
    #
    # @return [ActionLimiter::TokenBucket::Bucket] A `Bucket` struct containing
    # the name, value, max size, and period of the bucket.
    #
    # @example Incrementing a bucket's value
    #   # Initialize a new token bucket with a period of 5 seconds and a size of 20
    #   bucket = ActionLimiter::TokenBucket.new(period: 5, size: 20)
    #
    #   # Increment the "user:1" bucket and get its value
    #   bucket_value = bucket.increment('user:1').value

    def increment(bucket, time: Time.now)
      ActionLimiter.instrument('action_limiter.token_bucket.increment') do
        value = ActionLimiter.redis.call('EVALSHA', script_hash, 1, bucket_key(bucket), period.to_s, time.to_f.to_s)
        Bucket.new(name: bucket, value:, max_size: size, period:)
      end
    end

    ##
    # Delete a bucket's current value
    #
    # @param bucket [String] The name of the bucket to delete
    #
    # @return [void]
    def delete(bucket)
      ActionLimiter.instrument('action_limiter.token_bucket.reset') do
        ActionLimiter.redis.call('DEL', bucket_key(bucket))
      end
    end

    private

    def script_hash
      @script_hash ||= ActionLimiter.redis.call('SCRIPT', 'LOAD', ActionLimiter::SCRIPTS.fetch(:token_bucket))
    end

    def bucket_key(bucket)
      "#{namespace}/#{bucket}"
    end
  end
end
