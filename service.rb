require 'bundler/setup'
require 'daemons'

Daemons.run('sync.rb', { :dir => 'tmp', :log_output => true } )
