$:.unshift('.')
$:.unshift(File.join('.', 'lib'))
require 'sinatra'
require 'haml'
require 'helpers'
require 'htmlentities'
require 'trello'
require 'config'
require 'card'


get '/' do
  @user = Trello::Member.find("me")
  redirect to("/board/#{BOARD}")
end

get '/sync/trello' do
  sync_trello(BOARD)
  redirect to("/board/#{BOARD}")
end

get '/sync/zendesk' do
  Z.tickets_all.each { |ticket| get_issue(ticket["nice_id"]) }
  redirect to("/")
end

get '/board/:trello_id' do
  unless Board.with(:trello_id, params[:trello_id])
    redirect to("/board/new/#{params[:trello_id]}")
  end
  @board = Board.with(:trello_id, params[:trello_id])
  haml :cards
end

get '/board/new/:trello_id' do
  sync_trello(params[:trello_id])
  redirect to("/board/#{params[:trello_id]}")
end

get '/issue/:number' do
  if Issue.with(:number, params[:number]).nil?
    redirect to("/issue/new/zendesk/#{params[:number]}")
  end
  @issue = Issue.with(:number, params[:number])
  @status = Z.status(@issue.status).first
  haml :card
end

get '/issue/new/zendesk/:number' do
  @issue = get_issue(params[:number])
  redirect to("/board/#{BOARD}")
end

get '/issue/delete/:number' do
  Issue.with(:number, params[:number]).delete
  redirect back
end

get '/list/:list' do
  @list = List.with(:trello_id, params[:list])
  @board = @list.board
  haml :list
end

get '/list/new/:trello_id' do
  get_list(params[:trello_id])
  redirect to("/list/#{params[:trello_id]}")
end

get '/who/:number' do
  authors = Z.who_touched(params[:number])
  authors.each do |zendesk_id, name|
    if User.with(:zendesk_id, zendesk_id).nil?
      User.create :name => name, :zendesk_id => zendesk_id
    end
  end
  "#{authors}"
end

get '/user/delete/:id' do
  User[params[:id]].delete
end

get '/zendesk/:id' do
  coder = HTMLEntities.new
  coder.encode(Z.ticket(params[:id]))
end

