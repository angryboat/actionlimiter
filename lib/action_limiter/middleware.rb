# frozen_string_literal: true

begin
  require 'rack'
rescue LoadError
  # no-op
end

require 'action_limiter/middleware/ip' if defined?(Rack)

module ActionLimiter
  ##
  # Provides Rack middleware for the rate limiting algorithms
  module Middleware
  end
end
