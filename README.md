# ActionLimiter

[![Unit Test](https://github.com/angryboat/actionlimiter/actions/workflows/testing.yml/badge.svg)](https://github.com/angryboat/actionlimiter/actions/workflows/testing.yml) [![Linters](https://github.com/angryboat/actionlimiter/actions/workflows/linting.yml/badge.svg)](https://github.com/angryboat/actionlimiter/actions/workflows/linting.yml)

Provides Redis backed rate limiting for Rails applications.

## Installing

```shell
gem install actionlimiter
```

```shell
bundler add actionlimiter
```

## Usage

### Rails IP Middleware

```ruby
Rails.application.configure do |config|
  # Limit a single IP to 20 requests in a 5 second period.
  config.middleware.use(ActionLimiter::Middleware::IP, period: 5, size: 20)
end
```
