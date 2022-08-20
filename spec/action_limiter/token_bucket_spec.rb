# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ActionLimiter::TokenBucket do
  let(:instance) { described_class.new(period: 1, size: 5) }
  let(:key) { "token-bucket-test-#{rand(1_000...1_000_000)}" }

  describe '#increment_and_return_bucket' do
    it 'increments the number of events in the bucket' do
      first_count = instance.increment_and_return_bucket(key, Time.now).value
      second_count = instance.increment_and_return_bucket(key, Time.now).value

      expect(first_count).to eq 1
      expect(second_count).to eq 2
    end
  end

  describe '#limited?' do
    it 'returns true if the bucket has available tokens' do
      expect(instance.limited?(key)).to eq false
      expect(instance.limited?(key)).to eq false
      expect(instance.limited?(key)).to eq false
      expect(instance.limited?(key)).to eq false
      expect(instance.limited?(key)).to eq false
      expect(instance.limited?(key)).to eq true
    end
  end

  describe '#delete' do
    it 'delete the bucket value' do
      expect(instance.increment_and_return_bucket('key_one', Time.now).value).to eq 1
      expect(instance.increment_and_return_bucket('key_two', Time.now).value).to eq 1
      instance.delete('key_one')
      expect(instance.increment_and_return_bucket('key_one', Time.now).value).to eq 1
      expect(instance.increment_and_return_bucket('key_two', Time.now).value).to eq 2
    end
  end
end
