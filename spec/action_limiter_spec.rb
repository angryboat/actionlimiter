# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ActionLimiter do
  it 'has a version number' do
    expect(ActionLimiter::VERSION).not_to be nil
  end
end
