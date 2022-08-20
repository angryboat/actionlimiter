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
    # @private
    Bucket = Struct.new(:name, :value, :max_size, :period, keyword_init: true)

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
      @script_hash = ActionLimiter.with_redis_connection do |connection|
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
      increment_and_return_bucket(bucket, time).value > size
    end

    ##
    # Delete a bucket's current value
    #
    # @param bucket [String] The name of the bucket to delete
    #
    # @return [void]
    def delete(bucket)
      ActionLimiter.instrument('action_limiter.token_bucket.reset') do
        ActionLimiter.with_redis_connection do |connection|
          connection.del(bucket_key(bucket))
        end
      end
    end

    ##
    # @private
    def increment_and_return_bucket(bucket, time)
      ActionLimiter.instrument('action_limiter.token_bucket.increment') do
        ActionLimiter.with_redis_connection do |connection|
          value = connection.evalsha(@script_hash, [bucket_key(bucket)], [period.to_s, time.to_f])
          Bucket.new(name: bucket, value: value, max_size: size, period: period)
        end
      end
    end

    private

    def bucket_key(bucket)
      "#{namespace}/#{bucket}"
    end
  end
end
