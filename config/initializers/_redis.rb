# frozen_string_literal: true

# Redis gem doesn't have a built-in connection pooling,
# so we split this into two clients just to keep our example simple.

::REDIS1 = Redis.new(
  url: 'redis://localhost:6379/9'
)

::REDIS2 = Redis.new(
  url: 'redis://localhost:6379/9'
)
