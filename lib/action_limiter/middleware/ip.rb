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
      def initialize(app, options = {})
        @app = app
        @response_body = options.fetch(:response_body) { create_response_body }
        @headers = Hash(options.fetch(:headers, {})).dup
        @token_bucket = ActionLimiter::TokenBucket.new(
          period: options.fetch(:period, 1),
          size: options.fetch(:size, 100),
          namespace: options.fetch(:namespace, 'action_limiter/middleware/ip')
        )
      end

      ##
      # @private
      def call(env)
        remote_ip = env.fetch('action_dispatch.remote_ip')
        bucket_key = Digest::MD5.hexdigest(remote_ip.to_s)
        bucket = @token_bucket.increment(bucket_key, Time.now)

        if bucket.value > @token_bucket.size
          rate_limited_response(bucket)
        else
          status, headers, body = @app.call(env)

          headers.merge!(rate_limit_headers(bucket))

          [status, headers, body]
        end
      end

      private

      def response_body(bucket)
        if @response_body.respond_to?(:call)
          @response_body.call(bucket)
        else
          @response_body
        end
      end

      def create_response_body
        <<~BODY
          <html>
            <body>
              <h1>Too Many Requests</h1>
            </body>
          </html>
        BODY
      end

      def rate_limit_headers(bucket)
        {
          'X-Request-Count' => bucket.value.to_s,
          'X-Request-Period' => @token_bucket.period.to_s,
          'X-Request-Limit' => @token_bucket.size.to_s
        }
      end

      def response_headers(bucket)
        @headers['Content-Type'] = 'text/html' unless @headers.key?('Content-Type')

        @headers.merge(rate_limit_headers(bucket))
      end

      def rate_limited_response(bucket)
        [429, response_headers(bucket), [response_body(bucket)]]
      end
    end
  end
end
