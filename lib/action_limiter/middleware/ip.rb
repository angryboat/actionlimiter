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
      class ResponseBuilder
        ##
        # @private
        def call(_env)
          [429, response_headers, [response_body]]
        end

        private

        def response_body
          <<~BODY
            <html>
              <body>
                <h1>Too Many Requests</h1>
              </body>
            </html>
          BODY
        end

        def response_headers
          {
            'Content-Type' => 'text/html; charset=utf-8'
          }
        end
      end

      ##
      # @private
      def initialize(app, options = {})
        @app = app
        @response_builder = options.fetch(:response_builder) { ResponseBuilder.new }
        @token_bucket = ActionLimiter::TokenBucket.new(
          period: options.fetch(:period, 1),
          size: options.fetch(:size, 100),
          namespace: options.fetch(:namespace, 'action_limiter/middleware/ip')
        )
      end

      ##
      # @private
      def call(env)
        status, headers, body = _call(env)

        headers.merge!(create_rate_limit_headers(env))

        [status, headers, body]
      end

      private

      def _call(env)
        remote_ip = env.fetch('action_dispatch.remote_ip')
        bucket_key = Digest::MD5.hexdigest(remote_ip.to_s)
        bucket = @token_bucket.increment(bucket_key)

        env['action_limiter.ip_bucket'] = bucket

        if bucket.value > @token_bucket.size
          @response_builder.call(env)
        else
          @app.call(env)
        end
      end

      def create_rate_limit_headers(env)
        bucket = env.fetch('action_limiter.ip_bucket')

        {
          'X-Request-Count' => bucket.value.to_s,
          'X-Request-Period' => @token_bucket.period.to_s,
          'X-Request-Limit' => @token_bucket.size.to_s
        }
      end
    end
  end
end
