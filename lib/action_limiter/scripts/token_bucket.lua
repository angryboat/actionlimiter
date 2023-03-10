-- This script implements a token bucket algorithm in Redis.
--
-- The script takes two arguments:
--
--   ARGV[1] - The period of the token bucket, in seconds.
--   ARGV[2] - The current timestamp, in seconds since the epoch.
--
-- The script takes one key:
--
--   KEYS[1] - The name of the Redis sorted set to use as the token bucket.
--
-- The algorithm works by maintaining a sorted set in Redis, where each member
-- of the set is a timestamp indicating the time at which a token was added to
-- the bucket. When a request comes in, the script removes all timestamps in
-- the set that are older than the period, adds the current timestamp to the
-- set, and then returns the size of the set.
--
-- @param ARGV[1] The period of the token bucket, in seconds.
-- @param ARGV[2] The current timestamp, in seconds since the epoch.
-- @param KEYS[1] The name of the Redis sorted set to use as the token bucket.
-- @return The size of the Redis sorted set after adding the current timestamp.
local function token_bucket(period, ts, bucket_name)
  -- Convert the input arguments to numbers
  period = tonumber(period)
  ts = tonumber(ts)

  -- Calculate the minimum timestamp to keep in the bucket
  local min = ts - period

  -- Remove all timestamps older than the period from the bucket
  redis.call('ZREMRANGEBYSCORE', bucket_name, '-inf', min)

  -- Add the current timestamp to the bucket
  redis.call('ZADD', bucket_name, ts, ts)

  -- Set the expiration time for the bucket
  redis.call('EXPIRE', bucket_name, period + 2)

  -- Return the size of the bucket after adding the current timestamp
  return redis.call('ZCARD', bucket_name)
end

return token_bucket(tonumber(ARGV[1]), tonumber(ARGV[2]), KEYS[1])
