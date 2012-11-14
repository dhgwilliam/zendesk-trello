# In order to get this up and running:

1. Install [redis](http://redis.io)
2. `bundle install`
3. Fill in all the details in config/config.rb.example (TODO which should be commented soon)
3. start `redis` service
4. `bundle exec whenever --update-crontab`
5. `bundle exec rackup -p 4567 -s thin sync.rb` 
