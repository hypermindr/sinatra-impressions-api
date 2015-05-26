require './api-impressions.rb'
require 'redis-namespace'
run ApiImpressions

redis_conn = proc {
  redis_connection = Redis.new(:url => 'redis://smiths.hypermindr.com:6379/12')
  Redis::Namespace.new(ENV['RACK_ENV'], :redis => redis_connection)
}

Sidekiq.configure_client do |config|
  config.redis = ConnectionPool.new(size: 25, &redis_conn)
end
