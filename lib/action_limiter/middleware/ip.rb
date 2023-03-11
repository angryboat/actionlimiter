# frozen_string_literal: true

require 'action_limiter/token_bucket'
require 'rack'
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
      TOKEN_BUCKET_ENV_KEY = 'action_limiter.ip_bucket'

      ##
      # @private
      def initialize(app, options = {})
        @app = app
        @response_builder = options.fetch(:response_builder) { ResponseBuilder.new }
        @exclusion_list = Array(options[:exclusions])
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
        request = ::Rack::Request.new(env)

        return @app.call(env) if path_excluded?(request.path)

        bucket = increment_bucket_for_addr(request.ip)

        env[TOKEN_BUCKET_ENV_KEY] = bucket

        if bucket.limited?
          @response_builder.call(env)
        else
          @app.call(env)
        end
      end

      def increment_bucket_for_addr(ip)
        bucket_key = Digest::MD5.hexdigest(ip.to_s)
        @token_bucket.increment(bucket_key)
      end

      def path_excluded?(path)
        @exclusion_list.any? { |e| e.match?(path) }
      end

      def create_rate_limit_headers(env)
        return {} unless env.key?(TOKEN_BUCKET_ENV_KEY)

        {
          'X-Request-Count' => env[TOKEN_BUCKET_ENV_KEY].value.to_s,
          'X-Request-Period' => @token_bucket.period.to_s,
          'X-Request-Limit' => @token_bucket.size.to_s
        }
      end
    end
  end
end
