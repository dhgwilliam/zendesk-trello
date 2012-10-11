require 'rocco/tasks'

desc "Build Rocco Docs with `rake rocco`"
Rocco::make 'docs/', ['sync.rb', 'lib/*.rb']

desc "Start redis and run the sync webapp, also provides status"
task :start do
  ['redis-server', 'sync.rb'].each do |process|
    pid_file = File.join(File.dirname(__FILE__), 'tmp', process + '.pid')
    running_pid = %x{ps ax | grep #{process} | grep -v grep}.split.first
    if running_pid.nil? then running_pid = false else running_pid = running_pid.chomp end
    if File.exists?(pid_file)
      pid = %x{cat #{pid_file}}
      puts process + " pid is " + pid
    elsif !File.exists?(pid_file) and running_pid
      puts process + " is running, creating pid file for " + running_pid
      %x{echo #{running_pid} > tmp/#{process}.pid}
    else
      if process == "redis-server"
        %x{/usr/local/bin/redis-server /usr/local/etc/redis.conf > log/redis.log &}
        pid = $?.pid
      elsif process == "sync.rb"
        %x{ruby sync.rb &> log/sync.log &}
        pid = $?.pid + 1
        puts "starting #{process} with pid #{pid}"
        %x{echo #{pid} > tmp/#{process}.pid}
      end
    end
  end
end

desc "Stop the sync webapp"
task :stop do
  pid_file = File.join(File.dirname(__FILE__), 'tmp', 'sync.rb.pid')
  if File.exists?(pid_file)
    pid = %x{cat #{pid_file}}.chomp
    puts "killing #{pid}"
    %x{kill #{pid}}
    %x{ps ax | grep #{pid} | grep -v grep}
    %x{rm #{pid_file}}
  else
    puts "sync.rb not running"
  end
end
