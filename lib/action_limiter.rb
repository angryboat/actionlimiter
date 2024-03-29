# frozen_string_literal: true

require 'action_limiter/config'
require 'action_limiter/middleware'
require 'action_limiter/rails'
require 'action_limiter/token_bucket'
require 'action_limiter/version'

##
# ActionLimiter implementes rate limiting backed by Redis
#
# @author Maddie Schipper
# @since 0.1.0
module ActionLimiter
  ##
  # Perform configuration
  #
  # @author Maddie Schipper
  # @since 1.0.0
  def self.configure
    yield(Config.instance) if block_given?
  end
end
