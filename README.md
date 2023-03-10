# ActionLimiter

[![Ruby Gem](https://github.com/angryboat/actionlimiter/actions/workflows/ruby-gem.yml/badge.svg?event=push)](https://github.com/angryboat/actionlimiter/actions/workflows/ruby-gem.yml)

Provides Redis backed rate limiting for Rails applications.

## Installing

```shell
gem install actionlimiter
```

```shell
bundle add actionlimiter
```

## Usage

### Set Redis URL

```ruby
Rails.application.configure do |config|
  config.redis = { url: 'redis://localhost:6379/0' }
end
```

### Rails IP Middleware

```ruby
Rails.application.configure do |config|
  # Limit a single IP to 20 requests in a 5 second period.
  config.middleware.use(ActionLimiter::Middleware::IP, period: 5, size: 20)
end
```
