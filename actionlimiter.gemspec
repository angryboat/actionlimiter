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

  spec.required_ruby_version = Gem::Requirement.new('>= 2.7.0')

  spec.metadata['allowed_push_host'] = 'https://rubygems.pkg.github.com/angryboat'
  spec.metadata['homepage_uri'] = spec.homepage
  spec.metadata['source_code_uri'] = spec.homepage
  spec.metadata['changelog_uri'] = spec.homepage

  spec.files         = Dir['CHANGELOG.md', 'README.md', 'LICENSE', 'lib/**/*']
  spec.bindir        = 'exe'
  spec.executables   = spec.files.grep(%r{\Aexe/}) { |f| File.basename(f) }
  spec.require_paths = ['lib']

  spec.add_dependency 'connection_pool', '>= 2.0', '< 3.0'
  spec.add_dependency 'redis',           '>= 4.0', '< 5.0'
end
