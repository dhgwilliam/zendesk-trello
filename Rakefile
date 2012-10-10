task :start do
  if redis_pid = %x{ps ax | grep redis-server | grep -v grep}.split.first
    puts "redis is process #{redis_pid}"
    %x{echo #{redis_pid} > tmp/redis.pid}
  else
    %x{/usr/local/bin/redis-server /usr/local/etc/redis.conf > log/redis.log &}
    %x{echo #{$?.pid} > tmp/redis.pid}
    puts "started redis process #{cat tmp/redis.pid}"
  end

  ruby_pid = %x{ps ax | grep index.rb | grep -v grep}.split.first
  if !ruby_pid.nil?
    puts "app is process #{ruby_pid}"
    %x{echo #{ruby_pid} > tmp/ruby.pid}
  else
    %x{ruby index.rb &> log/sync.log &}
    %x{echo #{$?.pid} > tmp/ruby.pid}
    puts "started ruby process #{cat tmp/ruby.pid}"
    exec "tail -f log/sync.log"
  end
end

task :stop do
  ruby_pid = %x{cat tmp/ruby.pid}
  puts "killing #{ruby_pid}"
  %x{kill #{ruby_pid}}
  %x{rm tmp/ruby.pid}
end

task :status do
  redis_pid = %x{cat tmp/redis.pid}
  ruby_pid = %x{cat tmp/ruby.pid}

  if redis_pid
    puts "redis pid #{redis_pid}"
  else
    puts "redis is not running"
  end
  if ruby_pid
    puts "ruby pid #{ruby_pid}"
  else
    puts "the app is not running"
  end
end
