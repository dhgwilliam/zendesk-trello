# **sync.rb** is a Sinatra-based webapp that acts as a sync connector between 
# [Zendesk](http://www.zendesk.com) and [Trello](http://trello.com)
# The whole app would benefit from some caching and a resque worker queue, since it's
# getting a little slow.
#
# This is the Sinatra routes file that defines the API of the webapp
$:.unshift(File.dirname(__FILE__), File.join(File.dirname(__FILE__), 'lib'), File.join(File.dirname(__FILE__), 'config'))
require 'sinatra'
require 'haml'
require 'helpers'
require 'htmlentities'
require 'trello'
require 'config'
require 'models'

Sync = Rack::Builder.new do
#\ -p 4567 -s thin -E deployment -D
	run Sinatra::Application
end.to_app

# ## /
# Root route, simply redirects to the primary /board/ url
get '/' do
  @user = Trello::Member.find("me")
  redirect to("/board/#{BOARD}")
end

# ## /sync/trello
# This appears to be required to insert existing trello information into the db 
# and I can't really see any other reason for it
#
# **TODO**: convert this route to a rake or resque task
get '/sync/trello' do
  sync_trello(BOARD)
  redirect to("/board/#{BOARD}")
end

# ## /sync/zendesk
# Z.tickets_all loads all tickets from the RECENT view, so loading 
# this URL causes local updates to every ticket updated in the last 24 hours
#
# **TODO**: convert this route to a rake or resque task
get '/sync/zendesk' do
  # nice\_id may not still be supported, and get\_issue is a dumb method name
  #
  # **TODO**: rename get\_issue to something more meaningful
  Z.tickets_all.each { |ticket| get_issue(ticket["nice_id"]) }
  # this redirect is also wasteful
  redirect to("/")
end

# ## /board/4ed7e27fe6abb2517a21383d
# Displays the board but also causes a board to be loaded from Trello 
# if the board with :trello\_id hasn't been loaded yet
#
# **TODO**: convert redirect to resque task
get '/board/:trello_id' do
  unless Board.with(:trello_id, params[:trello_id])
    redirect to("/board/new/#{params[:trello_id]}")
  end
  @board = Board.with(:trello_id, params[:trello_id])
  haml :cards
end

# ## /board/new/4ed7e27fe6abb2517a21383d
# Pulls information from Trello to populate the local database
#
# **TODO**: convert sync\_trello rake or resque task
get '/board/new/:trello_id' do
  sync_trello(params[:trello_id])
  redirect to("/board/#{params[:trello_id]}")
end

# ## /issue/1979
# Displays details for local issue. If the issue doesn't exist yet, it pulls
# the ticket from Zendesk. :number appears to correlate to the Zendesk nice\_id
#
# **TODO**: convert redirect to trigger resque task
get '/issue/:number' do
  if Issue.with(:number, params[:number]).nil?
    redirect to("/issue/new/zendesk/#{params[:number]}")
  end
  @issue = Issue.with(:number, params[:number])
  @status = Z.status(@issue.status).first
  haml :card
end

# ## /issue/new/zendesk/1979
# Reload data from Zendesk for Zendesk ticket with id == :number
#
# **TODO**: convert this route to resque task
get '/issue/new/zendesk/:number' do
  @issue = get_issue(params[:number])
  redirect to("/board/#{BOARD}")
end

# ## /issue/delete/1979
# Triggers a delete of local issue object
get '/issue/delete/:number' do
  Issue.with(:number, params[:number]).delete
  redirect back
end

# ## /list/4f4e8539b7b81632280c9dd8
# Display all issues associated with cards in Trello list :list
get '/list/:list' do
  @list = List.with(:trello_id, params[:list])
  @board = @list.board
  haml :list
end

# ## /list/new/4f4e8539b7b81632280c9dd8
# Pull a list from Trello to local db and redirect to the list 
get '/list/new/:trello_id' do
  get_list(params[:trello_id])
  redirect to("/list/#{params[:trello_id]}")
end

# ## /who/1979
# Displays all the Zendesk users who "touched" a Zendesk ticket
#
# **TODO**: figure out the correct nouns and verbs for this route
# **WIP**
get '/who/:number' do
  authors = Z.who_touched(params[:number])
  authors.each do |zendesk_id, name|
    if User.with(:zendesk_id, zendesk_id).nil?
      User.create :name => name, :zendesk_id => zendesk_id
    end
  end
  "#{authors}"
end

# ## /user/delete/166929761
# Delete local User object associated with Zendesk user :id
get '/user/delete/:id' do
  User[params[:id]].delete
end

# ## /zendesk/1979
# Display JSON of Zendesk ticket :id
get '/zendesk/:id' do
  coder = HTMLEntities.new
  coder.encode(Z.ticket(params[:id]))
end

