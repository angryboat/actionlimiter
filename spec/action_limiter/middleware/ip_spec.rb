# frozen_string_literal: true

require 'spec_helper'

require 'securerandom'

RSpec.describe ActionLimiter::Middleware::IP do
  let(:response) { [200, {}, ['']] }

  let(:env) do
    {
      'action_dispatch.remote_ip' => SecureRandom.hex(16)
    }
  end

  let(:app) { double('next-app') }

  let(:response_builder) { double('response_builder') }

  let(:instance) do
    described_class.new(app, response_builder: response_builder, period: 1, size: 1)
  end

  before do
    allow(app).to receive(:call).and_return(response)
  end

  describe '#call' do
    it 'should call call the next middleware' do
      expect(app).to receive(:call).with(env).and_return(response)

      instance.call(env)
    end

    it 'should call the response builder if the request is rate limited' do
      expect(app).to receive(:call).with(env).and_return(response)

      instance.call(env)

      expect(response_builder).to receive(:call).with(env).and_return(response)

      instance.call(env)
    end
  end
end
