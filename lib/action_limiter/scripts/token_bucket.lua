-- Token Bucket

-- Period is the number of seconds for the token bucket TTL
local period = tonumber(ARGV[1])
-- The server timestamp for the value delivered
local ts = tonumber(ARGV[2])

-- Set the minimum time
local min = ts - period

-- Bucket Name
local bucket_name = KEYS[1]

redis.call('ZREMRANGEBYSCORE', bucket_name, '-inf', min)
redis.call('ZADD', bucket_name, ts, ts)
redis.call('EXPIRE', bucket_name, period + 2)

return redis.call('ZCARD', bucket_name)
