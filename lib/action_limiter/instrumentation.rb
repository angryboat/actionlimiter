# frozen_string_literal: true

begin
  require 'active_support/notifications'
rescue LoadError
  nil
end

##
# @private
module ActionLimiter
  def self.instrument(name, payload = {})
    if defined?(ActiveSupport::Notifications)
      ActiveSupport::Notifications.instrument(name, payload) { yield(payload) }
    else
      yield(payload)
    end
  end
end
