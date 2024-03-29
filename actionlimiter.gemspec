# frozen_string_literal: true

require_relative 'lib/action_limiter/version'

Gem::Specification.new do |spec|
  spec.name          = 'actionlimiter'
  spec.version       = ActionLimiter::VERSION
  spec.authors       = ['Maddie Schipper']
  spec.email         = ['maddie@angryboat.com']
  spec.summary       = 'Rate Limiting'
  spec.homepage      = 'https://github.com/angryboat/actionlimiter'
  spec.license       = 'MIT'
  spec.description   = <<~END_DESC
    Redis backed token bucket rate limting implementation.
  END_DESC

  spec.required_ruby_version = Gem::Requirement.new('>= 3.1')

  spec.metadata['allowed_push_host'] = 'https://rubygems.org'
  spec.metadata['rubygems_mfa_required'] = 'true'
  spec.metadata['homepage_uri'] = spec.homepage
  spec.metadata['source_code_uri'] = spec.homepage
  spec.metadata['changelog_uri'] = spec.homepage

  spec.files         = Dir['CHANGELOG.md', 'README.md', 'LICENSE', 'lib/**/*']
  spec.bindir        = 'exe'
  spec.executables   = spec.files.grep(%r{\Aexe/}) { |f| File.basename(f) }
  spec.require_paths = ['lib']

  spec.add_dependency 'redis-client', '>= 0.14', '< 1.0'
end
