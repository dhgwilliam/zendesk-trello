require 'sinatra'
require 'trello'
require 'json'
require 'haml'
require './config.rb'
include Trello
require 'httparty'
require 'htmlentities'

# LIST_TO_STATUS = {


get '/' do
  @user = Member.find("me")
  @boards = @user.boards
  haml :index
end

get '/user/:user' do
  @user = Member.find(params[:user])
  haml :user
end

get '/board/:board' do
  @board = Board.find(params[:board])
  @lists = []
  @board.lists.each { |list| @lists << list }
  haml :cards
end

get '/card/:card' do
  @card = Card.find(params[:card])
  # @ticket = Z.tickets(@card.name.scan(/#[0-9]+/).delete "#")
  @ticket = JSON::parse(Z.ticket(@card.name.scan(/\#[0-9]+/).first.delete "#"))
    @status = get_z_status(@ticket["status_id"])
  haml :card
end

get '/list/:list' do
  @list = List.find(params[:list])
  @board = Board.find(@list.board_id)
  haml :list
end

get '/zendesk/:ticket' do
  @ticket = JSON::parse(Z.ticket('999'))
  coder = HTMLEntities.new
  "#{@ticket}"
end

get '/favicon.ico' do
end

helpers do
  def get_z_status(status_id)
    case @ticket["status_id"]
    when 0
      @status = "New"
    when 1
      @status = "Open"
    when 2
      @status = "Pending"
    when 3
      @status = "Solved"
    when 4
      @status = "Closed"
    else
      @status = "Unknown"
    end
  end
end
