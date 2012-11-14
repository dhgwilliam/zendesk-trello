ROOT_DIR = "/home/david/src/zendesk-trello"

God.watch do |w|
  w.name = "zendesk-trello-sync"
	w.start = "cd #{ROOT_DIR}; ruby #{ROOT_DIR}/vendor/bundle/ruby/1.9.1/bin/rackup -p 4567 -E deployment -D -P tmp/rack.pid -s thin sync.rb"
	w.pid_file = File.join(ROOT_DIR, 'tmp/rack.pid')
	w.keepalive
end
